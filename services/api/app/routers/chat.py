"""Private client support threads with a shared, attributed staff inbox."""

import asyncio
import hashlib
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Request, Query
from pydantic import BaseModel, Field, field_validator
from firebase_admin import firestore

from ..firebase import FirebaseGateway, now
from ..security import CurrentUser, get_current_user

router = APIRouter(prefix="/chat", tags=["support chat"])
STAFF = {"administrator", "supervisor", "claims_officer"}


def allowed(user):
    if user.profile.role not in STAFF | {"client"}:
        raise HTTPException(
            403, "Support chat is available to clients and support staff."
        )


def membership(user, thread):
    allowed(user)
    if not thread or (
        user.profile.role == "client" and thread.get("client_id") != user.id
    ):
        raise HTTPException(404, "Conversation not found.")


def visible(thread, user):
    result = {
        key: value
        for key, value in thread.items()
        if key not in {"staff_seen", "client_seen"}
    }
    seen = (
        thread.get("client_seen", 0)
        if user.profile.role == "client"
        else thread.get("staff_seen", {}).get(user.id, 0)
    )
    result["unread_count"] = max(0, thread.get("last_sequence", 0) - seen)
    return result


class NewConversation(BaseModel):
    subject: str = Field(default="Claim questions", min_length=2, max_length=120)

    @field_validator("subject")
    @classmethod
    def clean(cls, value):
        if len(value.strip()) < 2:
            raise ValueError("Enter a subject with at least two characters.")
        return value.strip()


class NewMessage(BaseModel):
    client_message_id: str = Field(pattern=r"^[a-f0-9]{32}$")
    text: str = Field(min_length=1, max_length=4000)

    @field_validator("text")
    @classmethod
    def clean(cls, value):
        if not value.strip():
            raise ValueError("Enter a message.")
        return value.strip()


class ReadMessages(BaseModel):
    through_sequence: int = Field(ge=0, le=999999999999)


def thread_reference(store, identifier):
    if len(identifier) != 64 or any(c not in "0123456789abcdef" for c in identifier):
        raise HTTPException(404, "Conversation not found.")
    return store.db.collection("support_threads").document(identifier)


@router.post("/conversations", status_code=201)
async def create_conversation(
    payload: NewConversation,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
):
    allowed(user)
    if user.profile.role != "client":
        raise HTTPException(
            403, "Clients start support conversations; staff reply from the inbox."
        )
    store = FirebaseGateway(request)
    identifier = hashlib.sha256(user.id.encode()).hexdigest()
    ref = thread_reference(store, identifier)

    @firestore.transactional
    def create(tx):
        old = ref.get(transaction=tx)
        if old.exists:
            return visible(old.to_dict(), user)
        record = {
            "id": identifier,
            "client_id": user.id,
            "client_name": user.profile.display_name,
            "subject": payload.subject,
            "created_at": now(),
            "updated_at": now(),
            "last_sequence": 0,
            "last_message": "",
            "staff_seen": {},
            "client_seen": 0,
        }
        tx.set(ref, record)
        return visible(record, user)

    return await asyncio.to_thread(create, store.db.transaction())


@router.get("/conversations")
async def conversations(
    request: Request,
    before: str | None = None,
    limit: int = Query(default=30, ge=1, le=100),
    user: CurrentUser = Depends(get_current_user),
):
    allowed(user)
    store = FirebaseGateway(request)

    def load():
        if user.profile.role == "client":
            identifier = hashlib.sha256(user.id.encode()).hexdigest()
            snap = thread_reference(store, identifier).get()
            rows = [snap.to_dict()] if snap.exists else []
            return {
                "conversations": [visible(r, user) for r in rows],
                "next_before": None,
            }
        query = store.db.collection("support_threads").order_by(
            "updated_at", direction=firestore.Query.DESCENDING
        )
        if before:
            try:
                stamp, identifier = before.split("|", 1)
                datetime.fromisoformat(stamp)
                ref = thread_reference(store, identifier)
            except (ValueError, HTTPException):
                raise HTTPException(422, "Invalid conversation page cursor.")
            query = query.order_by(
                "__name__", direction=firestore.Query.DESCENDING
            ).start_after({"updated_at": stamp, "__name__": ref})
        else:
            query = query.order_by("__name__", direction=firestore.Query.DESCENDING)
        rows = [s.to_dict() for s in query.limit(limit + 1).stream()]
        cursor = (
            f"{rows[limit - 1]['updated_at']}|{rows[limit - 1]['id']}"
            if len(rows) > limit
            else None
        )
        return {
            "conversations": [visible(r, user) for r in rows[:limit]],
            "next_before": cursor,
        }

    return await asyncio.to_thread(load)


@router.get("/conversations/{identifier}/messages")
async def messages(
    identifier: str,
    request: Request,
    after: int | None = Query(default=None, ge=0, le=999999999999),
    before: int | None = Query(default=None, ge=1, le=999999999999),
    limit: int = Query(default=50, ge=1, le=100),
    user: CurrentUser = Depends(get_current_user),
):
    allowed(user)
    if after is not None and before is not None:
        raise HTTPException(422, "Use either before or after, not both.")
    store = FirebaseGateway(request)
    ref = thread_reference(store, identifier)

    def load():
        snap = ref.get()
        thread = snap.to_dict() if snap.exists else None
        membership(user, thread)
        if after is not None and after >= thread.get("last_sequence", 0):
            return {
                "conversation": visible(thread, user),
                "messages": [],
                "has_more": False,
            }
        collection = store.db.collection("support_messages")
        # Sequence IDs are allocated atomically with each message. Bounded batch
        # reads avoid downloading the whole history or requiring custom indexes.
        last = thread.get("last_sequence", 0)
        if after is not None:
            low, high = after + 1, min(last, after + limit)
            more = high < last
        else:
            high = min(last, before - 1 if before is not None else last)
            low = max(1, high - limit + 1)
            more = low > 1
        references = [
            collection.document(f"{identifier}_{n:012d}") for n in range(low, high + 1)
        ]
        rows = (
            [s.to_dict() for s in store.db.get_all(references) if s.exists]
            if references
            else []
        )
        rows.sort(key=lambda row: row["sequence"])
        return {
            "conversation": visible(thread, user),
            "messages": rows,
            "has_more": more,
        }

    return await asyncio.to_thread(load)


@router.post("/conversations/{identifier}/messages", status_code=201)
async def send_message(
    identifier: str,
    payload: NewMessage,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
):
    allowed(user)
    from .. import hardening

    wait = await asyncio.to_thread(hardening.consume, "chat:" + user.id, 60, 60)
    if wait:
        raise HTTPException(
            429,
            "Too many messages. Please wait before sending again.",
            headers={"Retry-After": str(wait)},
        )
    store = FirebaseGateway(request)
    ref = thread_reference(store, identifier)
    # Retries keep the same request key. The key is scoped to sender + thread.
    key = hashlib.sha256(
        f"{identifier}:{user.id}:{payload.client_message_id}".encode()
    ).hexdigest()
    receipt = store.db.collection("support_message_requests").document(key)

    @firestore.transactional
    def send(tx):
        snap = ref.get(transaction=tx)
        thread = snap.to_dict() if snap.exists else None
        membership(user, thread)
        prior = receipt.get(transaction=tx)
        if prior.exists:
            prior_message = (
                store.db.collection("support_messages")
                .document(prior.to_dict()["message_id"])
                .get(transaction=tx)
                .to_dict()
            )
            if prior_message["text"] != payload.text:
                raise HTTPException(
                    409, "This send key was used for a different message."
                )
            return prior_message
        sequence = thread.get("last_sequence", 0) + 1
        if sequence > 999999999999:
            raise HTTPException(
                409, "Conversation limit reached. Contact your administrator."
            )
        message_ref = store.db.collection("support_messages").document(
            f"{identifier}_{sequence:012d}"
        )
        message = {
            "id": message_ref.id,
            "conversation_id": identifier,
            "sequence": sequence,
            "client_message_id": payload.client_message_id,
            "sender_id": user.id,
            "sender_name": user.profile.display_name,
            "sender_role": user.profile.role,
            "text": payload.text,
            "sent_at": now(),
        }
        patch = {
            "last_sequence": sequence,
            "last_message": payload.text[:160],
            "last_sender_name": user.profile.display_name,
            "last_sender_role": user.profile.role,
            "updated_at": message["sent_at"],
        }
        if user.profile.role == "client":
            patch["client_seen"] = sequence
            patch["client_name"] = user.profile.display_name
        else:
            patch["staff_seen"] = {**thread.get("staff_seen", {}), user.id: sequence}
        audit = store.db.collection("audit_events").document()
        tx.set(message_ref, message)
        tx.set(
            receipt,
            {
                "message_id": message_ref.id,
                "conversation_id": identifier,
                "sender_id": user.id,
            },
        )
        tx.update(ref, patch)
        tx.set(
            audit,
            {
                "id": audit.id,
                "actor_id": user.id,
                "event_type": "CHAT_MESSAGE_SENT",
                "created_at": message["sent_at"],
                "metadata": {
                    "conversation_id": identifier,
                    "message_id": message_ref.id,
                },
            },
        )
        return message

    return await asyncio.to_thread(send, store.db.transaction())


@router.post("/conversations/{identifier}/read")
async def mark_read(
    identifier: str,
    payload: ReadMessages,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
):
    allowed(user)
    store = FirebaseGateway(request)
    ref = thread_reference(store, identifier)

    @firestore.transactional
    def read(tx):
        snap = ref.get(transaction=tx)
        thread = snap.to_dict() if snap.exists else None
        membership(user, thread)
        if payload.through_sequence > thread.get("last_sequence", 0):
            raise HTTPException(422, "Read position is beyond the conversation.")
        if user.profile.role == "client":
            patch = {
                "client_seen": max(
                    thread.get("client_seen", 0), payload.through_sequence
                )
            }
        else:
            seen = thread.get("staff_seen", {})
            patch = {
                "staff_seen": {
                    **seen,
                    user.id: max(seen.get(user.id, 0), payload.through_sequence),
                }
            }
        tx.update(ref, patch)
        return {"message": "Read position saved."}

    return await asyncio.to_thread(read, store.db.transaction())
