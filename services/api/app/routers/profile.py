import asyncio
from typing import Literal
from fastapi import APIRouter, Depends, Request
from firebase_admin import auth
from pydantic import BaseModel, Field

from ..schemas import Profile
from ..security import CurrentUser, get_current_user
from ..firebase import FirebaseGateway
from .auth import firebase_request, session


router = APIRouter(tags=["profile"])


@router.get("/profile", response_model=Profile)
async def profile(user: CurrentUser = Depends(get_current_user)) -> Profile:
    return user.profile


class ProfileEdit(BaseModel):
    display_name: str = Field(min_length=2, max_length=120)
    phone: str = Field(default="", max_length=32)
    theme: Literal["system", "light", "dark"] = "system"
    notifications_enabled: bool = True


@router.put("/profile", response_model=Profile)
async def edit_profile(
    payload: ProfileEdit,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
):
    store = FirebaseGateway(request)
    update = payload.model_dump()
    update["display_name"] = payload.display_name.strip()
    if len(update["display_name"]) < 2:
        from fastapi import HTTPException

        raise HTTPException(422, "Enter a valid display name.")
    await asyncio.to_thread(
        auth.update_user, user.id, display_name=update["display_name"], app=store.app
    )
    await asyncio.to_thread(
        store.db.collection("profiles").document(user.id).update, update
    )
    return {**user.profile.model_dump(), **update}


class PasswordEdit(BaseModel):
    current_password: str = Field(min_length=1, max_length=128)
    new_password: str = Field(min_length=12, max_length=128)


class UnlockRequest(BaseModel):
    password: str = Field(min_length=1, max_length=128)


@router.post("/profile/unlock")
async def unlock(
    payload: UnlockRequest,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
):
    from fastapi import HTTPException

    verified = await firebase_request(
        request,
        "signInWithPassword",
        {"email": user.email, "password": payload.password, "returnSecureToken": True},
    )
    if verified.get("localId") != user.id:
        raise HTTPException(403, "Please sign in again.")
    return {"message": "Session unlocked."}


@router.post("/profile/password")
async def change_password(
    payload: PasswordEdit,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
):
    if payload.current_password == payload.new_password:
        from fastapi import HTTPException

        raise HTTPException(
            422, "Choose a new password different from your current password."
        )
    verified = await firebase_request(
        request,
        "signInWithPassword",
        {
            "email": user.email,
            "password": payload.current_password,
            "returnSecureToken": True,
        },
    )
    result = await firebase_request(
        request,
        "update",
        {
            "idToken": verified["idToken"],
            "password": payload.new_password,
            "returnSecureToken": True,
        },
    )
    result["localId"] = user.id
    store = FirebaseGateway(request)
    await asyncio.to_thread(
        store.db.collection("profiles").document(user.id).update,
        {"must_change_password": False},
    )
    return await session(request, result)
