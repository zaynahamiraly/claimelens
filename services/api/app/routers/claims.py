from __future__ import annotations

import re
import asyncio
import uuid
import zipfile
import hashlib
from collections import Counter
from io import BytesIO
from pathlib import Path
from typing import Any
from typing import Literal

from fastapi import (
    APIRouter,
    BackgroundTasks,
    Depends,
    File,
    HTTPException,
    Query,
    Request,
    UploadFile,
    Header,
)

from ..processing import process_claim
from ..schemas import (
    ClaimDetails,
    ClaimDocument,
    ClaimSummary,
    ConfirmClaimRequest,
    DashboardSummary,
    ExtractedField,
    ProcessResult,
)
from ..security import CurrentUser, get_current_user
from ..firebase import FirebaseGateway
from ..workflow import workflow_details


router = APIRouter(prefix="/claims", tags=["claims"])
ALLOWED_MIME_TYPES = {
    "application/pdf": ".pdf",
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": ".docx",
}
CLAIM_SELECT = "id,reference,patient_name,provider_name,claimed_amount,currency,status,warning_count,created_at,assigned_to"


def summary(row: dict[str, Any]) -> ClaimSummary:
    return ClaimSummary(**{key: row.get(key) for key in CLAIM_SELECT.split(",")})


def valid_signature(content: bytes, mime_type: str) -> bool:
    if mime_type == "application/pdf":
        return content.startswith(b"%PDF-")
    if mime_type == "image/png":
        return content.startswith(b"\x89PNG\r\n\x1a\n")
    if mime_type == "image/jpeg":
        return content.startswith(b"\xff\xd8\xff")
    if (
        mime_type
        == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    ):
        try:
            with zipfile.ZipFile(BytesIO(content)) as archive:
                items = archive.infolist()
                return (
                    len(items) <= 1024
                    and sum(item.file_size for item in items) <= 50 * 1024 * 1024
                    and "word/document.xml" in archive.namelist()
                )
        except zipfile.BadZipFile:
            return False
    return False


async def accessible_claim(gateway: FirebaseGateway, reference: str) -> dict[str, Any]:
    rows = await gateway.records(
        "GET",
        "claims",
        params={"reference": f"eq.{reference}", "limit": "1"},
    )
    if not rows:
        raise HTTPException(status_code=404, detail="Claim not found.")
    return rows[0]


@router.get("", response_model=list[ClaimSummary])
async def list_claims(
    request: Request,
    status: str | None = Query(default=None),
    search: str | None = Query(default=None, max_length=100),
    scope: Literal["all", "mine", "unassigned"] = "all",
    view: Literal["all", "review"] = "all",
    limit: int = Query(default=50, ge=1, le=200),
    user: CurrentUser = Depends(get_current_user),
) -> list[ClaimSummary]:
    gateway = FirebaseGateway(request)
    params: dict[str, str] = {"order": "created_at.desc"}
    if status:
        params["status"] = f"eq.{status.upper()}"
    if search and search.strip():
        safe = re.sub(r"[^\w\s-]", "", search.strip())
        if safe:
            params["or"] = (
                f"(reference.ilike.*{safe}*,patient_name.ilike.*{safe}*,provider_name.ilike.*{safe}*)"
            )
    rows = await gateway.records("GET", "claims", params=params)
    if scope == "mine" and user.profile.role != "client":
        rows = [r for r in rows if r.get("assigned_to") == user.id]
    if scope == "unassigned":
        rows = [
            r
            for r in rows
            if not r.get("assigned_to")
            and r["status"] in {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"}
        ]
    if view == "review":
        rows = [
            r
            for r in rows
            if r["status"]
            in {
                "REVIEW_REQUIRED",
                "INFORMATION_RECEIVED",
                "INFORMATION_REQUIRED",
                "VERIFIED",
            }
        ]
    return [summary(row) for row in rows[:limit]]


@router.get("/dashboard", response_model=DashboardSummary)
async def dashboard(
    request: Request,
    user: CurrentUser = Depends(get_current_user),
) -> DashboardSummary:
    gateway = FirebaseGateway(request)
    params: dict[str, str] = {"order": "created_at.desc"}
    rows = await gateway.records("GET", "claims", params=params)
    counts = Counter(row["status"] for row in rows)
    action_statuses = {
        "client": {"UPLOADED", "INFORMATION_REQUIRED", "PROCESSING_FAILED"},
        "claims_officer": {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"},
        "supervisor": {"VERIFIED", "REVIEW_REQUIRED", "INFORMATION_RECEIVED"},
        "administrator": {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"},
        "finance": {"APPROVED", "PAYMENT_PENDING"},
    }.get(user.profile.role, set())
    return DashboardSummary(
        action_required_claims=[
            summary(row) for row in rows if row["status"] in action_statuses
        ][:5],
        unassigned=sum(
            not row.get("assigned_to")
            and row["status"] in {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"}
            for row in rows
        ),
        by_status=dict(counts),
        total_claims=len(rows),
        processing=counts["PROCESSING"],
        review_required=counts["REVIEW_REQUIRED"],
        verified=counts["VERIFIED"],
        processing_failed=counts["PROCESSING_FAILED"],
        recent_claims=[summary(row) for row in rows[:5]],
    )


@router.post("", response_model=ClaimDetails, status_code=201)
async def create_claim(
    request: Request,
    files: list[UploadFile] = File(...),
    idempotency_key: str | None = Header(default=None, min_length=16, max_length=100),
    user: CurrentUser = Depends(get_current_user),
) -> ClaimDetails:
    gateway = FirebaseGateway(request)
    settings = gateway.settings
    if not files or len(files) > settings.max_claim_documents:
        raise HTTPException(
            status_code=422,
            detail=f"Upload between 1 and {settings.max_claim_documents} documents.",
        )
    prepared: list[tuple[UploadFile, bytes]] = []
    for upload in files:
        content = await upload.read(settings.max_file_bytes + 1)
        if upload.content_type not in ALLOWED_MIME_TYPES:
            raise HTTPException(
                status_code=422,
                detail=f"{upload.filename or 'Document'} is not a PDF, PNG, JPEG, or DOCX file.",
            )
        if not content or len(content) > settings.max_file_bytes:
            raise HTTPException(
                status_code=422,
                detail=f"{upload.filename or 'Document'} must be smaller than {settings.max_file_bytes // (1024 * 1024)} MB.",
            )
        if not valid_signature(content, upload.content_type):
            raise HTTPException(
                status_code=422,
                detail=f"{upload.filename or 'Document'} does not match its reported file type.",
            )
        prepared.append((upload, content))

    rows = await gateway.records(
        "POST",
        "claims",
        json={
            "created_by": user.id,
            "client_id": user.id,
            "patient_name": "",
            "provider_name": "",
            "currency": "MUR",
            "status": "UPLOADED",
            "request_key": idempotency_key,
            "upload_complete": False,
        },
    )
    claim = rows[0]
    if claim.pop("_reused", False):
        if not claim.get("upload_complete"):
            raise HTTPException(
                409,
                "This upload is already being saved. Check your drafts before trying again.",
            )
        return await get_claim(claim["reference"], request, user)
    documents: list[dict[str, Any]] = []
    uploaded_paths: list[str] = []
    try:
        for upload, content in prepared:
            original = Path(
                upload.filename or f"document{ALLOWED_MIME_TYPES[upload.content_type]}"
            ).name
            safe_name = re.sub(r"[^A-Za-z0-9._-]", "_", original)[:160]
            storage_path = f"{user.id}/{claim['id']}/{uuid.uuid4().hex}-{safe_name}"
            await gateway.upload(storage_path, content, upload.content_type)
            uploaded_paths.append(storage_path)
            inserted = await gateway.records(
                "POST",
                "claim_documents",
                json={
                    "claim_id": claim["id"],
                    "uploaded_by": user.id,
                    "document_type": "UNKNOWN",
                    "original_name": original,
                    "storage_path": storage_path,
                    "mime_type": upload.content_type,
                    "size_bytes": len(content),
                    "content_sha256": hashlib.sha256(content).hexdigest(),
                },
            )
            documents.append(inserted[0])
            await gateway.records(
                "POST",
                "audit_events",
                json={
                    "claim_id": claim["id"],
                    "actor_id": user.id,
                    "event_type": "DOCUMENT_UPLOADED",
                    "metadata": {"document_id": inserted[0]["id"], "name": original},
                },
            )
        await gateway.records(
            "POST",
            "audit_events",
            json={
                "claim_id": claim["id"],
                "actor_id": user.id,
                "event_type": "CLAIM_CREATED",
                "metadata": {"document_count": len(documents)},
            },
        )
    except Exception:
        try:
            await gateway.delete_objects(uploaded_paths)
            await gateway.records(
                "DELETE", "claims", params={"id": f"eq.{claim['id']}"}
            )
        except Exception:
            pass
        raise
    await gateway.records(
        "PATCH",
        "claims",
        service=True,
        params={"id": f"eq.{claim['id']}"},
        json={"upload_complete": True},
    )
    return ClaimDetails(
        **summary(claim).model_dump(),
        documents=[ClaimDocument(**document, fields=[]) for document in documents],
        audit_events=[],
    )


@router.delete("/{reference}")
async def delete_draft(
    reference: str, request: Request, user: CurrentUser = Depends(get_current_user)
):
    gateway = FirebaseGateway(request)
    claim = await accessible_claim(gateway, reference)
    if (
        user.profile.role != "client"
        or claim.get("client_id") != user.id
        or claim["status"] not in {"UPLOADED", "PROCESSING_FAILED"}
        or claim.get("submitted_at")
        or claim.get("needs_reconfirmation")
    ):
        raise HTTPException(403, "Only your unsubmitted drafts can be deleted.")
    documents = await gateway.records(
        "GET", "claim_documents", params={"claim_id": f"eq.{claim['id']}"}
    )
    old_status = await gateway.reserve_draft_deletion(claim['id'])
    try:
        await gateway.delete_objects([d["storage_path"] for d in documents])
        await gateway.records("DELETE", "claims", service=True, params={"id": f"eq.{claim['id']}"})
    except Exception:
        await asyncio.to_thread(gateway.db.collection('claims').document(claim['id']).update, {'status': old_status})
        raise
    return {"message": "Draft and its documents deleted."}


@router.get("/{reference}", response_model=ClaimDetails)
async def get_claim(
    reference: str,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
) -> ClaimDetails:
    gateway = FirebaseGateway(request)
    claim = await accessible_claim(gateway, reference)
    documents = await gateway.records(
        "GET",
        "claim_documents",
        params={"claim_id": f"eq.{claim['id']}", "order": "created_at.asc"},
    )
    fields = await gateway.records(
        "GET",
        "claim_extracted_fields",
        params={"claim_id": f"eq.{claim['id']}", "order": "created_at.asc"},
    )
    audit = await gateway.records(
        "GET",
        "audit_events",
        params={
            "claim_id": f"eq.{claim['id']}",
            "order": "created_at.desc",
            "limit": "100",
        },
    )
    grouped: dict[str, list[ExtractedField]] = {}
    for field in fields:
        grouped.setdefault(field.get("document_id") or "", []).append(
            ExtractedField(**field)
        )
    response_documents = []
    if user.profile.role == "finance":
        documents = []
        audit = [
            event
            for event in audit
            if event.get("event_type")
            in {"CLAIM_APPROVED", "CLAIM_PAYMENT_PENDING", "CLAIM_PAID"}
        ]
    for document in documents:
        signed_url = await gateway.signed_url(document["storage_path"])
        response_documents.append(
            ClaimDocument(
                **document,
                signed_url=signed_url,
                fields=grouped.get(document["id"], []),
            )
        )
    return ClaimDetails(
        **summary(claim).model_dump(),
        documents=response_documents,
        audit_events=audit,
        **(await workflow_details(gateway, claim)),
        information=claim.get("information") or {},
    )


@router.post("/{reference}/process", response_model=ProcessResult)
async def process(
    reference: str,
    request: Request,
    background_tasks: BackgroundTasks,
    background: bool = False,
    user: CurrentUser = Depends(get_current_user),
) -> ProcessResult:
    gateway = FirebaseGateway(request)
    claim = await accessible_claim(gateway, reference)
    if claim["status"] not in {"UPLOADED", "PROCESSING_FAILED"}:
        raise HTTPException(
            status_code=409, detail="This claim is not available for processing."
        )
    await gateway.acquire_processing(claim["id"])
    if background:
        from ..jobs import enqueue

        try:
            await enqueue(gateway, claim, user.id)
        except Exception:
            await gateway.records(
                "PATCH",
                "claims",
                service=True,
                params={"id": f"eq.{claim['id']}"},
                json={"status": "PROCESSING_FAILED"},
            )
            raise HTTPException(
                503, "The processing queue is unavailable. Please retry."
            )
        return ProcessResult(
            claim_reference=reference,
            status="PROCESSING",
            document_count=0,
            extracted_field_count=0,
        )
    return await finish_processing(gateway, claim, user.id)


async def finish_processing(gateway, claim, actor_id):
    try:
        return await process_claim(
            gateway,
            claim,
            actor_id,
            return_status="INFORMATION_RECEIVED"
            if claim.get("needs_reconfirmation")
            else "UPLOADED",
        )
    except Exception:
        # A failure before the processing job is created must release the claim.
        await gateway.records(
            "PATCH",
            "claims",
            service=True,
            params={"id": f"eq.{claim['id']}"},
            json={"status": "PROCESSING_FAILED"},
        )
        raise


@router.post("/{reference}/confirm")
async def confirm_claim(
    reference: str,
    payload: ConfirmClaimRequest,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
) -> dict[str, str]:
    gateway = FirebaseGateway(request)
    claim = await accessible_claim(gateway, reference)
    if (
        user.profile.role != "client"
        or claim.get("client_id") != user.id
        or claim.get('status') not in {'UPLOADED', 'PROCESSING_FAILED'}
        or claim.get('needs_reconfirmation')
        or claim.get('submitted_at')
    ):
        raise HTTPException(
            status_code=403, detail="Only the claim owner can confirm this draft."
        )
    return {"status": await gateway.confirm(claim["id"], payload)}
