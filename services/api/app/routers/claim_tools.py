"""Claim information, source previews, receipts, and controlled appeals."""

import asyncio
from datetime import date
from io import BytesIO

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import Response
from firebase_admin import firestore
from pydantic import BaseModel, Field

from ..firebase import FirebaseGateway, now
from ..security import CurrentUser, get_current_user
from ..workflow import write_event
from .claims import accessible_claim
from .workspace import administrator

router = APIRouter(tags=["claim tools"])


class ClaimInformation(BaseModel):
    member_number: str = Field(default="", max_length=80)
    policy_number: str = Field(default="", max_length=80)
    treatment_date: date | None = None
    description: str = Field(default="", max_length=2000)


class BusinessSettings(BaseModel):
    require_member_number: bool = False
    require_policy_number: bool = False
    required_documents: list[str] = Field(
        default_factory=lambda: ["Invoice or receipt", "Supporting medical evidence"],
        max_length=20,
    )
    allowed_currencies: list[str] = Field(
        default_factory=lambda: ["MUR", "USD", "EUR", "GBP"],
        min_length=1,
        max_length=20,
    )
    maximum_appeals: int = Field(default=1, ge=0, le=3)
    support_email: str = Field(default="", max_length=254)
    privacy_notice: str = Field(
        default="Use ClaimLens only for claims you are authorized to submit. Uploaded medical evidence is shared with authorized reviewers for claim processing.",
        max_length=8000,
    )


async def business_settings(store):
    snapshot = await asyncio.to_thread(
        store.db.collection("configuration").document("business").get
    )
    return BusinessSettings.model_validate(
        snapshot.to_dict() if snapshot.exists else {}
    ).model_dump(mode="json")


@router.get("/settings")
async def settings(request: Request, user: CurrentUser = Depends(get_current_user)):
    return await business_settings(FirebaseGateway(request))


@router.put("/settings")
async def edit_settings(
    payload: BusinessSettings,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
):
    administrator(user)
    currencies = sorted(set(c.strip().upper() for c in payload.allowed_currencies))
    if any(len(c) != 3 or not c.isalpha() for c in currencies):
        raise HTTPException(422, "Currencies must be three-letter codes.")
    if payload.support_email and (
        "@" not in payload.support_email or "\n" in payload.support_email
    ):
        raise HTTPException(422, "Enter a valid support email.")
    store = FirebaseGateway(request)
    values = {**payload.model_dump(mode="json"), "allowed_currencies": currencies}
    await asyncio.to_thread(
        store.db.collection("configuration").document("business").set, values
    )
    from .workspace import account_event

    await account_event(store, user.id, "BUSINESS_SETTINGS_UPDATED", user.id)
    return values


@router.put("/claims/{reference}/information")
async def information(
    reference: str,
    payload: ClaimInformation,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
):
    store = FirebaseGateway(request)
    claim = await accessible_claim(store, reference)
    if user.profile.role != "client" or claim.get("client_id") != user.id:
        raise HTTPException(403, "Only the claim owner can update draft information.")
    if payload.treatment_date and payload.treatment_date > date.today():
        raise HTTPException(422, "The treatment date cannot be in the future.")
    ref = store.db.collection("claims").document(claim["id"])

    @firestore.transactional
    def save(transaction):
        current = ref.get(transaction=transaction).to_dict()
        if current.get("status") not in {
            "UPLOADED",
            "PROCESSING_FAILED",
        } or current.get("needs_reconfirmation"):
            raise HTTPException(
                409, "Submitted claim information cannot be changed as a draft."
            )
        transaction.update(
            ref, {"information": payload.model_dump(mode="json"), "updated_at": now()}
        )

    await asyncio.to_thread(save, store.db.transaction())
    return {"message": "Draft information saved."}


class Appeal(BaseModel):
    reason: str = Field(min_length=10, max_length=2000)


@router.post("/claims/{reference}/appeal")
async def appeal(
    reference: str,
    payload: Appeal,
    request: Request,
    user: CurrentUser = Depends(get_current_user),
):
    store = FirebaseGateway(request)
    claim = await accessible_claim(store, reference)
    if user.profile.role != "client" or claim.get("client_id") != user.id:
        raise HTTPException(403, "Only the claim owner can request an appeal.")
    policy = await business_settings(store)
    ref = store.db.collection("claims").document(claim["id"])

    @firestore.transactional
    def submit(transaction):
        current = ref.get(transaction=transaction).to_dict()
        if (
            current["status"] != "REJECTED"
            or current.get("appeal_count", 0) >= policy["maximum_appeals"]
        ):
            raise HTTPException(409, "An appeal is not available for this claim.")
        row = store.db.collection("claim_appeals").document()
        transaction.set(
            row,
            {
                "id": row.id,
                "claim_id": claim["id"],
                "reason": payload.reason.strip(),
                "previous_decision": current.get("decision_notes"),
                "created_at": now(),
                "created_by": user.id,
            },
        )
        transaction.update(
            ref,
            {
                "status": "REVIEW_REQUIRED",
                "assigned_to": None,
                "verified_by": None,
                "verified_at": None,
                "decision_notes": None,
                "approved_amount": None,
                "appeal_count": current.get("appeal_count", 0) + 1,
                "updated_at": now(),
            },
        )
        write_event(
            store.db,
            transaction,
            current,
            user.id,
            "APPEAL_SUBMITTED",
            {"reason": payload.reason.strip()},
        )

    await asyncio.to_thread(submit, store.db.transaction())
    return {"message": "Appeal submitted to the review queue."}


@router.get("/claims/{reference}/documents/{identifier}/preview")
async def preview(
    reference: str,
    identifier: str,
    request: Request,
    page: int = Query(default=1, ge=1, le=100),
    user: CurrentUser = Depends(get_current_user),
):
    if user.profile.role == "finance":
        raise HTTPException(403, "Medical document access requires review permission.")
    store = FirebaseGateway(request)
    claim = await accessible_claim(store, reference)
    rows = await store.records(
        "GET",
        "claim_documents",
        params={"claim_id": f"eq.{claim['id']}", "id": f"eq.{identifier}"},
    )
    if not rows:
        raise HTTPException(404, "Document not found.")
    row = rows[0]
    content = await store.download(row["storage_path"])

    def render():
        if row["mime_type"] == "application/pdf":
            import pymupdf

            with pymupdf.open(stream=content, filetype="pdf") as document:
                if document.needs_pass or page > len(document):
                    raise HTTPException(
                        422,
                        "This page is unavailable or the document is password protected.",
                    )
                return (
                    document[page - 1]
                    .get_pixmap(matrix=pymupdf.Matrix(1.5, 1.5), alpha=False)
                    .tobytes("png"),
                    "image/png",
                    len(document),
                )
        if row["mime_type"].startswith("image/"):
            from PIL import Image

            with Image.open(BytesIO(content)) as image:
                image.thumbnail((2048, 2048))
                output = BytesIO()
                image.convert("RGB").save(output, format="PNG")
                return output.getvalue(), "image/png", 1
        from docx import Document

        document = Document(BytesIO(content))
        text = "\n".join(
            [p.text for p in document.paragraphs]
            + [
                " | ".join(c.text for c in row.cells)
                for table in document.tables
                for row in table.rows
            ]
        )
        return text.encode(), "text/plain; charset=utf-8", 1

    data, mime, pages = await asyncio.to_thread(render)
    return Response(
        data,
        media_type=mime,
        headers={
            "Cache-Control": "private, no-store",
            "X-Document-Pages": str(pages),
            "X-Content-Type-Options": "nosniff",
        },
    )


@router.get("/claims/{reference}/receipt")
async def receipt(
    reference: str, request: Request, user: CurrentUser = Depends(get_current_user)
):
    store = FirebaseGateway(request)
    claim = await accessible_claim(store, reference)
    if claim["status"] in {"UPLOADED", "PROCESSING", "PROCESSING_FAILED"}:
        raise HTTPException(409, "A receipt is available after submission.")

    def create():
        import pymupdf

        document = pymupdf.open()
        page = document.new_page()
        lines = [
            "ClaimLens",
            "Claim submission receipt",
            "",
            f"Reference: {claim['reference']}",
            f"Patient: {claim.get('patient_name', '')}",
            f"Provider: {claim.get('provider_name', '')}",
            f"Claimed: {claim.get('currency', 'MUR')} {claim.get('claimed_amount', '')}",
            f"Status: {claim['status'].replace('_', ' ')}",
            f"Submitted: {claim.get('submitted_at', claim['created_at'])[:10]}",
            "",
            "This receipt confirms submission. It is not an approval or a promise of payment.",
        ]
        page.insert_textbox(
            pymupdf.Rect(45, 45, 550, 780), "\n".join(lines), fontsize=12
        )
        result = document.tobytes()
        document.close()
        return result

    data = await asyncio.to_thread(create)
    return Response(
        data,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{reference}-receipt.pdf"',
            "Cache-Control": "private, no-store",
        },
    )


@router.get("/claims/{reference}/receipt/preview")
async def receipt_preview(
    reference: str, request: Request, user: CurrentUser = Depends(get_current_user)
):
    pdf = await receipt(reference, request, user)

    def render():
        import pymupdf

        with pymupdf.open(stream=pdf.body, filetype="pdf") as document:
            return (
                document[0]
                .get_pixmap(matrix=pymupdf.Matrix(1.5, 1.5), alpha=False)
                .tobytes("png")
            )

    return Response(
        await asyncio.to_thread(render),
        media_type="image/png",
        headers={"X-Document-Pages": "1", "Cache-Control": "private, no-store"},
    )
