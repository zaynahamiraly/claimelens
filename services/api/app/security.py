from __future__ import annotations

from dataclasses import dataclass
import asyncio
from firebase_admin import auth

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from .schemas import Profile
from .firebase import FirebaseGateway, firebase_app


bearer = HTTPBearer(auto_error=False)


@dataclass(frozen=True)
class CurrentUser:
    id: str
    email: str | None
    token: str
    profile: Profile


async def get_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
) -> CurrentUser:
    if not credentials or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication required."
        )

    try:
        user = await asyncio.to_thread(
            auth.verify_id_token,
            credentials.credentials,
            app=firebase_app(),
            check_revoked=True,
        )
    except (auth.InvalidIdTokenError, auth.UserNotFoundError, ValueError):
        raise HTTPException(401, "Your session has expired. Please sign in again.")
    gateway = FirebaseGateway(request)
    record = await gateway.profile(user["uid"])
    if not record or record.get("status") != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="This account is not active."
        )
    profile = Profile(**record)
    profile.email_verified = bool(user.get("email_verified", False))
    if profile.must_change_password and request.url.path not in {
        "/api/v1/profile",
        "/api/v1/profile/password",
        "/api/v1/profile/unlock",
        "/api/v1/auth/logout",
    }:
        raise HTTPException(403, "Change your temporary password before continuing.")
    current = CurrentUser(
        id=user["uid"],
        email=user.get("email"),
        token=credentials.credentials,
        profile=profile,
    )
    request.state.current_user = current
    return current
