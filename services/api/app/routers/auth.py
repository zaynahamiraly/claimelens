import asyncio
from fastapi import APIRouter, Depends, HTTPException, Request, Response
from firebase_admin import auth
from ..config import get_settings
from ..firebase import FirebaseGateway, firebase_app
from ..schemas import (
    AuthSession,
    LoginRequest,
    RefreshRequest,
    SignupRequest,
    EmailRequest,
)
from ..security import CurrentUser, get_current_user

router = APIRouter(prefix="/auth", tags=["authentication"])


async def firebase_request(request, action, payload, *, refresh=False):
    key = get_settings().firebase_api_key
    if not key:
        raise HTTPException(503, "Authentication is not configured on the server.")
    url = (
        f"https://securetoken.googleapis.com/v1/token?key={key}"
        if refresh
        else f"https://identitytoolkit.googleapis.com/v1/accounts:{action}?key={key}"
    )
    response = await request.app.state.http.post(
        url, **({"data": payload} if refresh else {"json": payload})
    )
    if not response.is_success:
        code = response.json().get("error", {}).get("message", "AUTHENTICATION_FAILED")
        messages = {
            "INVALID_LOGIN_CREDENTIALS": "Invalid email or password.",
            "EMAIL_NOT_FOUND": "Invalid email or password.",
            "INVALID_PASSWORD": "Invalid email or password.",
            "EMAIL_EXISTS": "An account already exists. Sign in or reset your password.",
            "TOO_MANY_ATTEMPTS_TRY_LATER": "Too many attempts. Please try again later.",
            "OPERATION_NOT_ALLOWED": "Email sign-in is not enabled.",
            "USER_DISABLED": "This account is disabled.",
        }
        raise HTTPException(
            400,
            messages.get(
                code, "Authentication request could not be completed. Please try again."
            ),
        )
    return response.json()


async def session(request, data):
    token = data.get("idToken") or data.get("id_token")
    uid = data.get("localId") or data.get("user_id")
    firebase_user = await asyncio.to_thread(auth.get_user, uid, app=firebase_app())
    if firebase_user.disabled:
        raise HTTPException(403, "This account is disabled.")
    profile = await FirebaseGateway(request).ensure_profile(
        uid, firebase_user.display_name, firebase_user.email or ""
    )
    profile = {**profile, "email_verified": firebase_user.email_verified}
    if profile.get("status") != "active":
        raise HTTPException(403, "This account is not active.")
    return AuthSession(
        access_token=token,
        refresh_token=data.get("refreshToken") or data.get("refresh_token"),
        expires_in=int(data.get("expiresIn") or data.get("expires_in", 3600)),
        user=profile,
    )


@router.post("/login", response_model=AuthSession)
async def login(payload: LoginRequest, request: Request):
    data = await firebase_request(
        request,
        "signInWithPassword",
        {
            "email": payload.email.strip().lower(),
            "password": payload.password,
            "returnSecureToken": True,
        },
    )
    return await session(request, data)


@router.post("/refresh", response_model=AuthSession)
async def refresh(payload: RefreshRequest, request: Request):
    data = await firebase_request(
        request,
        "",
        {"grant_type": "refresh_token", "refresh_token": payload.refresh_token},
        refresh=True,
    )
    return await session(request, data)


@router.post("/signup")
async def signup(payload: SignupRequest, request: Request):
    data = await firebase_request(
        request,
        "signUp",
        {
            "email": payload.email.strip().lower(),
            "password": payload.password,
            "displayName": payload.display_name.strip(),
            "returnSecureToken": True,
        },
    )
    await FirebaseGateway(request).ensure_profile(
        data["localId"],
        payload.display_name.strip(),
        payload.email.strip().lower(),
        verification_required=True,
    )
    try:
        await firebase_request(
            request,
            "sendOobCode",
            {"requestType": "VERIFY_EMAIL", "idToken": data["idToken"]},
        )
    except HTTPException:
        return {
            "message": "Account created. You can sign in. The confirmation email could not be sent yet."
        }
    return {
        "message": "Account created. Check your email for confirmation, then sign in."
    }


@router.post("/forgot-password")
async def forgot_password(payload: EmailRequest, request: Request):
    try:
        await firebase_request(
            request,
            "sendOobCode",
            {"requestType": "PASSWORD_RESET", "email": payload.email.strip().lower()},
        )
    except HTTPException as error:
        if error.detail != "Invalid email or password.":
            raise
    return {
        "message": "If an account exists, Firebase will email you a password reset link. Open it to choose a new password, then return here to sign in."
    }


@router.post("/logout", status_code=204)
async def logout(user: CurrentUser = Depends(get_current_user)):
    await asyncio.to_thread(auth.revoke_refresh_tokens, user.id, app=firebase_app())
    return Response(status_code=204)


@router.post("/verification-email")
async def send_verification(
    request: Request, user: CurrentUser = Depends(get_current_user)
):
    if user.profile.email_verified:
        return {"message": "Your email is already verified."}
    await firebase_request(
        request, "sendOobCode", {"requestType": "VERIFY_EMAIL", "idToken": user.token}
    )
    return {"message": "Verification email sent. Check your inbox and spam folder."}
