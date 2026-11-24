"""Private device registration and generic, nonmedical push messages."""

import asyncio
import hashlib
import logging
from types import SimpleNamespace
from fastapi import APIRouter, Depends, HTTPException, Request
from firebase_admin import messaging
from google.cloud.firestore_v1.base_query import FieldFilter
from pydantic import BaseModel, Field
from .firebase import FirebaseGateway, now
from .security import CurrentUser, get_current_user

router = APIRouter(tags=["devices"])
log = logging.getLogger(__name__)


class Device(BaseModel):
    token: str = Field(min_length=20, max_length=4096)


@router.post("/devices")
async def register(
    payload: Device, request: Request, user: CurrentUser = Depends(get_current_user)
):
    store = FirebaseGateway(request)
    ref = store.db.collection("device_tokens").document(
        hashlib.sha256(payload.token.encode()).hexdigest()
    )
    await asyncio.to_thread(
        ref.set, {"uid": user.id, "token": payload.token, "updated_at": now()}
    )
    return {"message": "Device registered."}


@router.delete("/devices")
async def unregister(
    payload: Device, request: Request, user: CurrentUser = Depends(get_current_user)
):
    store = FirebaseGateway(request)
    ref = store.db.collection("device_tokens").document(
        hashlib.sha256(payload.token.encode()).hexdigest()
    )
    snapshot = await asyncio.to_thread(ref.get)
    if snapshot.exists and snapshot.to_dict().get("uid") != user.id:
        raise HTTPException(404, "Device not found.")
    await asyncio.to_thread(ref.delete)
    return {"message": "Device removed."}


def deliver_pending(store):
    for snapshot in (
        store.db.collection("notifications")
        .where(filter=FieldFilter("push_state", "==", "PENDING"))
        .limit(30)
        .stream()
    ):
        notice = snapshot.to_dict()
        uid = notice["recipient_id"]
        profile = store.db.collection("profiles").document(uid).get().to_dict() or {}
        devices = list(
            store.db.collection("device_tokens")
            .where(filter=FieldFilter("uid", "==", uid))
            .stream()
        )
        if (
            profile.get("status") != "active"
            or not profile.get("notifications_enabled", True)
            or not devices
        ):
            snapshot.reference.update({"push_state": "SKIPPED"})
            continue
        try:
            message = messaging.MulticastMessage(
                fids=[s.to_dict()["token"] for s in devices[:100]],
                notification=messaging.Notification(
                    title="ClaimLens update",
                    body="Open ClaimLens to securely view an update to your workspace.",
                ),
                data={"reference": notice.get("reference", "")},
                android=messaging.AndroidConfig(
                    notification=messaging.AndroidNotification(visibility="private", tag=snapshot.id, icon="ic_stat_claimlens")
                ),
            )
            result = messaging.send_each_for_multicast(message, app=store.app)
            for device, response in zip(devices, result.responses):
                if isinstance(response.exception, messaging.UnregisteredError):
                    device.reference.delete()
            snapshot.reference.update(
                {
                    "push_state": "SENT" if result.success_count else "FAILED",
                    "push_completed_at": now(),
                }
            )
        except Exception:
            attempts = notice.get("push_attempts", 0) + 1
            snapshot.reference.update(
                {
                    "push_attempts": attempts,
                    "push_state": "FAILED" if attempts >= 3 else "PENDING",
                }
            )
            log.warning(
                "A push notification could not be delivered. In-app notifications remain available."
            )


async def push_loop():
    while True:
        try:
            store = FirebaseGateway(SimpleNamespace(state=SimpleNamespace()))
            await asyncio.to_thread(deliver_pending, store)
        except asyncio.CancelledError:
            raise
        except Exception:
            log.warning("Push delivery unavailable; retrying later.")
        await asyncio.sleep(30)
