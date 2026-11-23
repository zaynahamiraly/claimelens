from __future__ import annotations

import re
import uuid
import zipfile
from collections import Counter
from io import BytesIO
from pathlib import Path
from typing import Any

from fastapi import APIRouter, Depends, File, HTTPException, Query, Request, UploadFile

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
    if mime_type == "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
        try:
            with zipfile.ZipFile(BytesIO(content)) as archive:
                return "word/document.xml" in archive.namelist()
        except zipfile.BadZipFile:
            return False
    return False


async def accessible_claim(gateway: FirebaseGateway, token: str, reference: str) -> dict[str, Any]:
    rows = await gateway.records(
        "GET",
        "claims",
        token=token,
        params={"reference": f"eq.{reference}", "select": "*", "limit": "1"},
    )
    if not rows:
        raise HTTPException(status_code=404, detail="Claim not found.")
    return rows[0]


@router.get("", response_model=list[ClaimSummary])
async def list_claims(
    request: Request,
    status: str | None = Query(default=None),
    search: str | None = Query(default=None, max_length=100),
    limit: int = Query(default=50, ge=1, le=200),
    user: CurrentUser = Depends(get_current_user),
) -> list[ClaimSummary]:
    gateway = FirebaseGateway(request)
    params: dict[str, str] = {"select": CLAIM_SELECT, "order": "created_at.desc", "limit": str(limit)}
    if user.profile.role == "claims_officer":
        params["assigned_to"] = f"eq.{user.id}"
    if status:
        params["status"] = f"eq.{status.upper()}"
    if search and search.strip():
        safe = re.sub(r"[^\w\s-]", "", search.strip())
        if safe:
            params["or"] = f"(reference.ilike.*{safe}*,patient_name.ilike.*{safe}*,provider_name.ilike.*{safe}*)"
    rows = await gateway.records("GET", "claims", token=user.token, params=params)
    return [summary(row) for row in rows]


@router.get("/dashboard", response_model=DashboardSummary)
async def dashboard(
    request: Request,
    user: CurrentUser = Depends(get_current_user),
) -> DashboardSummary:
    gateway = FirebaseGateway(request)
    params: dict[str, str] = {"select": CLAIM_SELECT, "order": "created_at.desc", "limit": "500"}
    if user.profile.role == "claims_officer":
        params["assigned_to"] = f"eq.{user.id}"
    rows = await gateway.records("GET", "claims", token=user.token, params=params)
    counts = Counter(row["status"] for row in rows)
    return DashboardSummary(
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
    user: CurrentUser = Depends(get_current_user),
) -> ClaimDetails:
    gateway = FirebaseGateway(request)
    settings = gateway.settings
    if not files or len(files) > settings.max_claim_documents:
        raise HTTPException(status_code=422, detail=f"Upload between 1 and {settings.max_claim_documents} documents.")
    prepared: list[tuple[UploadFile, bytes]] = []
    for upload in files:
        content = await upload.read(settings.max_file_bytes + 1)
        if upload.content_type not in ALLOWED_MIME_TYPES:
            raise HTTPException(status_code=422, detail=f"{upload.filename or 'Document'} is not a PDF, PNG, JPEG, or DOCX file.")
        if not content or len(content) > settings.max_file_bytes:
            raise HTTPException(status_code=422, detail=f"{upload.filename or 'Document'} must be smaller than {settings.max_file_bytes // (1024 * 1024)} MB.")
        if not valid_signature(content, upload.content_type):
            raise HTTPException(status_code=422, detail=f"{upload.filename or 'Document'} does not match its reported file type.")
        prepared.append((upload, content))

    rows = await gateway.records(
        "POST",
        "claims",
        token=user.token,
        json={"created_by": user.id, "client_id": user.id, "patient_name": "", "provider_name": "", "currency": "MUR", "status": "UPLOADED"},
        prefer="return=representation",
    )
    claim = rows[0]
    documents: list[dict[str, Any]] = []
    uploaded_paths: list[str] = []
    try:
        for upload, content in prepared:
            original = Path(upload.filename or f"document{ALLOWED_MIME_TYPES[upload.content_type]}").name
            safe_name = re.sub(r"[^A-Za-z0-9._-]", "_", original)[:160]
            storage_path = f"{user.id}/{claim['id']}/{uuid.uuid4().hex}-{safe_name}"
            await gateway.upload(storage_path, content, upload.content_type, user.token)
            uploaded_paths.append(storage_path)
            inserted = await gateway.records(
                "POST",
                "claim_documents",
                token=user.token,
                json={
                    "claim_id": claim["id"],
                    "uploaded_by": user.id,
                    "document_type": "UNKNOWN",
                    "original_name": original,
                    "storage_path": storage_path,
                    "mime_type": upload.content_type,
                    "size_bytes": len(content),
                },
                prefer="return=representation",
            )
            documents.append(inserted[0])
            await gateway.records(
                "POST",
                "audit_events",
                token=user.token,
                json={"claim_id": claim["id"], "actor_id": user.id, "event_type": "DOCUMENT_UPLOADED", "metadata": {"document_id": inserted[0]["id"], "name": original}},
            )
        await gateway.records("POST", "audit_events", token=user.token, json={"claim_id": claim["id"], "actor_id": user.id, "event_type": "CLAIM_CREATED", "metadata": {"document_count": len(documents)}})
    except Exception:
        try:
            await gateway.delete_objects(uploaded_paths, user.token)
            await gateway.records("DELETE", "claims", token=user.token, params={"id": f"eq.{claim['id']}"})
        except Exception:
            pass
        raise
    return ClaimDetails(
        **summary(claim).model_dump(),
        documents=[ClaimDocument(**document, fields=[]) for document in documents],
        audit_events=[],
    )


@router.get("/{reference}", response_model=ClaimDetails)
async def get_claim(
    reference: str,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
) -> ClaimDetails:
    gateway = FirebaseGateway(request)
    claim = await accessible_claim(gateway, user.token, reference)
    documents = await gateway.records("GET", "claim_documents", token=user.token, params={"claim_id": f"eq.{claim['id']}", "select": "*", "order": "created_at.asc"})
    fields = await gateway.records("GET", "claim_extracted_fields", token=user.token, params={"claim_id": f"eq.{claim['id']}", "select": "*", "order": "created_at.asc"})
    audit = await gateway.records("GET", "audit_events", token=user.token, params={"claim_id": f"eq.{claim['id']}", "select": "id,event_type,metadata,created_at,actor_id", "order": "created_at.desc", "limit": "100"})
    grouped: dict[str, list[ExtractedField]] = {}
    for field in fields:
        grouped.setdefault(field.get("document_id") or "", []).append(ExtractedField(**field))
    response_documents = []
    for document in documents:
        signed_url = await gateway.signed_url(document["storage_path"], user.token)
        response_documents.append(ClaimDocument(**document, signed_url=signed_url, fields=grouped.get(document["id"], [])))
    return ClaimDetails(**summary(claim).model_dump(), documents=response_documents, audit_events=audit)


@router.post("/{reference}/process", response_model=ProcessResult)
async def process(
    reference: str,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
) -> ProcessResult:
    gateway = FirebaseGateway(request)
    claim = await accessible_claim(gateway, user.token, reference)
    if claim["status"] not in {"UPLOADED", "PROCESSING_FAILED"}:
        raise HTTPException(status_code=409, detail="This claim is not available for processing.")
    await gateway.acquire_processing(claim["id"])
    try:
        return await process_claim(gateway, claim, user.id)
    except Exception:
        # A failure before the processing job is created must release the claim.
        await gateway.records('PATCH', 'claims', service=True, params={'id': f"eq.{claim['id']}"}, json={'status':'PROCESSING_FAILED'})
        raise


@router.post("/{reference}/confirm")
async def confirm_claim(
    reference: str,
    payload: ConfirmClaimRequest,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
) -> dict[str, str]:
    gateway = FirebaseGateway(request)
    claim = await accessible_claim(gateway, user.token, reference)
    if user.profile.role != "client" or claim.get("client_id") != user.id or claim.get("status") != "UPLOADED":
        raise HTTPException(status_code=403, detail="Only the claim owner can confirm this draft.")
    return {"status": await gateway.confirm(claim["id"], payload)}
