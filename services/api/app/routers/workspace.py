import asyncio
from collections import Counter, defaultdict
from datetime import date
from decimal import Decimal
from pathlib import Path
from typing import Literal
import re
import uuid

from fastapi import (
    APIRouter,
    BackgroundTasks,
    Depends,
    File,
    Form,
    HTTPException,
    Request,
    UploadFile,
)
from firebase_admin import auth, firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from pydantic import BaseModel, Field, field_validator

from ..firebase import FirebaseGateway, now
from ..schemas import SignupRequest
from ..permissions import PERMISSIONS, require
from ..security import CurrentUser, get_current_user
from ..workflow import WorkflowInput, apply_action, write_event, STAFF
from .claims import accessible_claim, valid_signature, ALLOWED_MIME_TYPES

router = APIRouter(tags=["workspace"])


def staff(user):
    if user.profile.role not in STAFF:
        raise HTTPException(403, "Staff permission required.")


def administrator(user):
    if user.profile.role != "administrator":
        raise HTTPException(403, "Administrator permission required.")


@router.get("/workspace/officers")
async def officers(request: Request, user: CurrentUser = Depends(get_current_user)):
    staff(user)
    store = FirebaseGateway(request)

    def load():
        rows = [
            s.to_dict()
            for s in store.db.collection("profiles")
            .where(filter=FieldFilter("role", "==", "claims_officer"))
            .stream()
        ]
        return [
            {"id": r["id"], "display_name": r["display_name"]}
            for r in rows
            if r.get("status") == "active"
        ]

    return await asyncio.to_thread(load)


@router.post("/claims/{reference}/actions/{action}")
async def claim_action(
    reference: str,
    action: str,
    payload: WorkflowInput,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
):
    store = FirebaseGateway(request)
    claim = await accessible_claim(store, reference)
    updated = await apply_action(store, claim["id"], action, payload)
    return {"status": updated["status"], "message": "Claim updated successfully."}


@router.post("/claims/{reference}/information/{request_id}/respond")
async def information_response(
    reference: str,
    request_id: str,
    request: Request,
    background_tasks: BackgroundTasks,
    background: bool = Form(default=False),
    response_text: str = Form(default="", max_length=4000),
    files: list[UploadFile] = File(default=[]),
    user: CurrentUser = Depends(get_current_user),
):
    store = FirebaseGateway(request)
    claim = await accessible_claim(store, reference)
    if (
        user.profile.role != "client"
        or claim.get("client_id") != user.id
        or claim["status"] != "INFORMATION_REQUIRED"
    ):
        raise HTTPException(
            403, "Only the claim owner can respond to this information request."
        )
    if not response_text.strip() and not files:
        raise HTTPException(422, "Enter a response or attach supporting documents.")
    if len(files) > store.settings.max_claim_documents:
        raise HTTPException(422, "Too many documents in this response.")
    existing = await store.records(
        "GET", "claim_documents", params={"claim_id": f"eq.{claim['id']}"}
    )
    if len(existing) + len(files) > store.settings.max_claim_documents:
        raise HTTPException(422, "A claim can have at most ten documents.")
    prepared = []
    for upload in files:
        content = await upload.read(store.settings.max_file_bytes + 1)
        if (
            upload.content_type not in ALLOWED_MIME_TYPES
            or not content
            or len(content) > store.settings.max_file_bytes
            or not valid_signature(content, upload.content_type)
        ):
            raise HTTPException(
                422, "Attach valid PDF, Word, PNG, or JPEG files under 10 MB."
            )
        name = re.sub(
            r"[^A-Za-z0-9._-]", "_", Path(upload.filename or "document").name
        )[:160]
        path = f"{user.id}/{claim['id']}/{uuid.uuid4().hex}-{name}"
        prepared.append((path, content, upload.content_type, name, str(uuid.uuid4())))
    uploaded = []
    committed = False
    try:
        for path, content, mime, _, _ in prepared:
            await store.upload(path, content, mime)
            uploaded.append(path)
        ref = store.db.collection("claims").document(claim["id"])
        info_ref = store.db.collection("claim_information_requests").document(
            request_id
        )

        @firestore.transactional
        def submit(transaction):
            current = ref.get(transaction=transaction).to_dict()
            info = info_ref.get(transaction=transaction)
            if (
                not current
                or current.get("client_id") != user.id
                or current["status"] != "INFORMATION_REQUIRED"
                or not info.exists
                or info.to_dict().get("claim_id") != claim["id"]
                or info.to_dict().get("status") != "OPEN"
            ):
                raise HTTPException(409, "This information request is no longer open.")
            transaction.update(
                info_ref,
                {
                    "status": "ANSWERED",
                    "response_text": response_text.strip(),
                    "responded_at": now(),
                    "document_count": len(prepared),
                },
            )
            transaction.update(
                ref,
                {
                    "status": "PROCESSING" if prepared else "INFORMATION_RECEIVED",
                    "needs_reconfirmation": bool(prepared),
                    "updated_at": now(),
                },
            )
            for path, content, mime, name, identifier in prepared:
                transaction.set(
                    store.db.collection("claim_documents").document(identifier),
                    {
                        "id": identifier,
                        "claim_id": claim["id"],
                        "uploaded_by": user.id,
                        "information_request_id": request_id,
                        "original_name": name,
                        "storage_path": path,
                        "mime_type": mime,
                        "size_bytes": len(content),
                        "document_type": "UNKNOWN",
                        "extraction_status": "PENDING",
                        "include_in_total": False,
                        "created_at": now(),
                    },
                )
            write_event(
                store.db,
                transaction,
                current,
                user.id,
                "INFORMATION_RECEIVED",
                {"document_count": len(prepared)},
            )
            if prepared and background:
                from ..jobs import queue_record

                transaction.set(
                    store.db.collection("processing_queue").document(claim["id"]),
                    queue_record({**current, "needs_reconfirmation": True}, user.id),
                )

        await asyncio.to_thread(submit, store.db.transaction())
        committed = True
        if prepared:
            if background:
                return {
                    "message": "Your response was submitted. Supporting documents are being processed."
                }
            # Process the added evidence without returning the submitted claim to draft.
            from ..processing import process_claim

            try:
                await process_claim(
                    store, claim, user.id, return_status="INFORMATION_RECEIVED"
                )
            except Exception:
                await asyncio.to_thread(
                    ref.update, {"status": "PROCESSING_FAILED", "updated_at": now()}
                )
                return {
                    "message": "Your response was saved. Document processing needs a retry from the claim page."
                }
        return {"message": "Your response was submitted to the review team."}
    finally:
        if not committed and uploaded:
            await store.delete_objects(uploaded)


async def finish_information_processing(store, claim, actor):
    from .claims import finish_processing

    try:
        await finish_processing(store, {**claim, "needs_reconfirmation": True}, actor)
    except Exception:
        # finish_processing records PROCESSING_FAILED; the response remains saved.
        pass


@router.get("/notifications")
async def notifications(
    request: Request, user: CurrentUser = Depends(get_current_user)
):
    store = FirebaseGateway(request)

    def load():
        rows = [
            s.to_dict()
            for s in store.db.collection("notifications")
            .where(filter=FieldFilter("recipient_id", "==", user.id))
            .stream()
        ]
        return sorted(rows, key=lambda r: r.get("created_at", ""), reverse=True)[:100]

    return await asyncio.to_thread(load)


@router.post("/notifications/{identifier}/read")
async def read_notice(
    identifier: str, request: Request, user: CurrentUser = Depends(get_current_user)
):
    store = FirebaseGateway(request)

    def mark():
        ref = store.db.collection("notifications").document(identifier)
        snapshot = ref.get()
        if not snapshot.exists or snapshot.to_dict().get("recipient_id") != user.id:
            raise HTTPException(404, "Notification not found.")
        ref.update({"read": True})

    await asyncio.to_thread(mark)
    return {"message": "Notification marked as read."}


@router.get("/workspace/audit")
async def audit(
    request: Request, search: str = "", user: CurrentUser = Depends(get_current_user)
):
    require(user, "audit.view")
    store = FirebaseGateway(request)
    claims = await store.records("GET", "claims")
    allowed = {c["id"]: c["reference"] for c in claims}

    def load():
        rows = []
        for snapshot in store.db.collection("audit_events").stream():
            value = snapshot.to_dict()
            if value.get("claim_id") in allowed or (
                user.profile.role == "administrator" and not value.get("claim_id")
            ):
                value["reference"] = allowed.get(
                    value.get("claim_id"), "Account administration"
                )
                if (
                    not search
                    or search.lower()
                    in (value["reference"] + " " + value["event_type"]).lower()
                ):
                    rows.append(value)
        return sorted(rows, key=lambda row: row.get("created_at", ""), reverse=True)[
            :200
        ]

    return await asyncio.to_thread(load)


@router.get("/workspace/analytics")
async def analytics(
    request: Request,
    from_date: date | None = None,
    to_date: date | None = None,
    user: CurrentUser = Depends(get_current_user),
):
    require(user, "analytics.view")
    if from_date and to_date and from_date > to_date:
        raise HTTPException(422, "Start date must be before the end date.")
    rows = await FirebaseGateway(request).records("GET", "claims")
    rows = [
        r
        for r in rows
        if (not from_date or r["created_at"][:10] >= from_date.isoformat())
        and (not to_date or r["created_at"][:10] <= to_date.isoformat())
    ]
    totals = defaultdict(
        lambda: {"claimed": Decimal(0), "approved": Decimal(0), "paid": Decimal(0)}
    )
    for row in rows:
        currency = row.get("currency", "MUR")
        totals[currency]["claimed"] += Decimal(str(row.get("claimed_amount") or 0))
        totals[currency]["approved"] += Decimal(str(row.get("approved_amount") or 0))
        if row["status"] == "PAID":
            totals[currency]["paid"] += Decimal(str(row.get("approved_amount") or 0))
    return {
        "total": len(rows),
        "by_status": dict(Counter(r["status"] for r in rows)),
        "monthly": dict(sorted(Counter(r["created_at"][:7] for r in rows).items())),
        "amounts": {
            k: {n: str(v) for n, v in amounts.items()} for k, amounts in totals.items()
        },
        "unassigned": sum(
            not r.get("assigned_to")
            and r["status"] in {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"}
            for r in rows
        ),
        "scope": "Assigned and unassigned review claims"
        if user.profile.role == "claims_officer"
        else "All accessible claims",
    }


class UserCreate(SignupRequest):
    role: Literal[
        "client", "claims_officer", "supervisor", "administrator", "finance"
    ] = "client"
    permissions: list[str] = Field(default_factory=list, max_length=7)

    @field_validator("permissions")
    @classmethod
    def valid_permissions(cls, values):
        if set(values) - PERMISSIONS or "users.manage" in values:
            raise ValueError(
                "Choose valid claim, finance, analytics or audit permissions. User administration requires the administrator role."
            )
        return sorted(set(values))


class UserEdit(BaseModel):
    display_name: str = Field(min_length=2, max_length=120)
    role: Literal["client", "claims_officer", "supervisor", "administrator", "finance"]
    permissions: list[str] = Field(default_factory=list, max_length=7)
    valid_permissions = field_validator("permissions")(
        UserCreate.valid_permissions.__func__
    )
    status: Literal["active", "inactive"]

    @field_validator("display_name")
    @classmethod
    def valid_name(cls, value):
        if len(value.strip()) < 2:
            raise ValueError("Enter a name with at least two characters.")
        return value.strip()


@router.get("/users")
async def users(request: Request, user: CurrentUser = Depends(get_current_user)):
    administrator(user)
    store = FirebaseGateway(request)
    return await asyncio.to_thread(
        lambda: sorted(
            [
                s.to_dict()
                for s in store.db.collection("profiles").stream()
                if not s.to_dict().get("deleted")
            ],
            key=lambda row: row.get("display_name", "").lower(),
        )
    )


@router.post("/users", status_code=201)
async def create_user(
    payload: UserCreate, request: Request, user: CurrentUser = Depends(get_current_user)
):
    administrator(user)
    store = FirebaseGateway(request)
    try:
        created = await asyncio.to_thread(
            auth.create_user,
            email=payload.email.strip().lower(),
            password=payload.password,
            display_name=payload.display_name.strip(),
            app=store.app,
        )
    except auth.EmailAlreadyExistsError:
        raise HTTPException(409, "This email already has an account.")
    try:
        record = {
            "id": created.uid,
            "display_name": payload.display_name.strip(),
            "email": payload.email.strip().lower(),
            "role": payload.role,
            "status": "active",
            "created_at": now(),
            "permissions": [] if payload.role == "client" else payload.permissions,
            "must_change_password": True,
        }
        await asyncio.to_thread(
            store.db.collection("profiles").document(created.uid).create, record
        )
    except Exception:
        await asyncio.to_thread(auth.delete_user, created.uid, app=store.app)
        raise
    await account_event(store, user.id, "USER_CREATED", created.uid)
    return record


async def account_event(store, actor, event, target):
    ref = store.db.collection("audit_events").document()
    await asyncio.to_thread(
        ref.set,
        {
            "id": ref.id,
            "actor_id": actor,
            "event_type": event,
            "metadata": {"target_user_id": target},
            "created_at": now(),
        },
    )


async def change_user(store, user, uid, payload, delete=False):
    ref = store.db.collection("profiles").document(uid)

    @firestore.transactional
    def change(transaction):
        snapshot = ref.get(transaction=transaction)
        if not snapshot.exists:
            raise HTTPException(404, "User not found.")
        old = snapshot.to_dict()
        if uid == user.id and (
            delete or payload.role != "administrator" or payload.status != "active"
        ):
            raise HTTPException(
                422,
                "You cannot disable, delete, or demote your own administrator account.",
            )
        admins = list(
            store.db.collection("profiles")
            .where(filter=FieldFilter("role", "==", "administrator"))
            .stream(transaction=transaction)
        )
        if (
            old.get("role") == "administrator"
            and old.get("status") == "active"
            and (
                delete or payload.role != "administrator" or payload.status != "active"
            )
            and sum(a.to_dict().get("status") == "active" for a in admins) <= 1
        ):
            raise HTTPException(422, "At least one active administrator must remain.")
        update = (
            {"status": "inactive", "deleted": True} if delete else payload.model_dump()
        )
        transaction.update(ref, update)
        event = store.db.collection("audit_events").document()
        transaction.set(
            event,
            {
                "id": event.id,
                "actor_id": user.id,
                "event_type": "USER_DELETED" if delete else "USER_ACCESS_UPDATED",
                "metadata": {
                    "target_user_id": uid,
                    "previous_role": old.get("role"),
                    "new_role": update.get("role", old.get("role")),
                    "status": update["status"],
                },
                "created_at": now(),
            },
        )

    await asyncio.to_thread(change, store.db.transaction())


@router.put("/users/{uid}")
async def edit_user(
    uid: str,
    payload: UserEdit,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
):
    administrator(user)
    store = FirebaseGateway(request)
    await change_user(store, user, uid, payload)
    return {"message": "User access updated."}


@router.delete("/users/{uid}")
async def delete_user(
    uid: str, request: Request, user: CurrentUser = Depends(get_current_user)
):
    administrator(user)
    store = FirebaseGateway(request)
    await change_user(store, user, uid, None, delete=True)
    try:
        await asyncio.to_thread(auth.delete_user, uid, app=store.app)
    except auth.UserNotFoundError:
        pass
    return {"message": "Login account deleted. Claim and audit records are retained."}


@router.post("/users/{uid}/password-reset")
async def user_reset(
    uid: str, request: Request, user: CurrentUser = Depends(get_current_user)
):
    administrator(user)
    store = FirebaseGateway(request)
    target = await asyncio.to_thread(auth.get_user, uid, app=store.app)
    link = await asyncio.to_thread(
        auth.generate_password_reset_link, target.email, app=store.app
    )
    await account_event(store, user.id, "PASSWORD_RECOVERY_CREATED", uid)
    return {
        "link": link,
        "message": "Share this recovery link privately with the account owner.",
    }


class AdminPassword(BaseModel):
    new_password: str = Field(min_length=12, max_length=128)
    admin_password: str = Field(min_length=1, max_length=128)


@router.post("/users/{uid}/password")
async def set_user_password(
    uid: str,
    payload: AdminPassword,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
):
    administrator(user)
    if uid == user.id:
        raise HTTPException(422, "Use Account → Change password for your own account.")
    from .auth import firebase_request

    verified = await firebase_request(
        request,
        "signInWithPassword",
        {
            "email": user.email,
            "password": payload.admin_password,
            "returnSecureToken": True,
        },
    )
    if verified.get("localId") != user.id:
        raise HTTPException(403, "Administrator authentication failed.")
    store = FirebaseGateway(request)
    profile = await store.profile(uid)
    if not profile or profile.get("deleted"):
        raise HTTPException(404, "User not found.")
    await asyncio.to_thread(
        auth.update_user, uid, password=payload.new_password, app=store.app
    )
    # Firebase invalidates existing refresh tokens when the password changes.
    # Avoid a second, local-clock revocation after the update: clock skew could
    # otherwise invalidate a user's immediate sign-in with the new password.
    await asyncio.to_thread(
        store.db.collection("profiles").document(uid).update,
        {"must_change_password": True},
    )
    await account_event(store, user.id, "TEMPORARY_PASSWORD_SET", uid)
    return {
        "message": "Temporary password set. The user must change it when they sign in."
    }
