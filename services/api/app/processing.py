from __future__ import annotations

import asyncio
import hashlib
import io
from datetime import datetime, timezone
from typing import Any

from fastapi import HTTPException

from .extraction import TextDocument, classify_document, extract_fields
from .schemas import ProcessResult
from .firebase import FirebaseGateway


def _extract_docx(content: bytes) -> tuple[str, str, float]:
    from docx import Document

    document = Document(io.BytesIO(content))
    parts = [paragraph.text for paragraph in document.paragraphs]
    for table in document.tables:
        for row in table.rows:
            parts.append("\t".join(cell.text for cell in row.cells))
    return "\n".join(value for value in parts if value.strip()), "docx_text", 0.98


def _ocr_image(content: bytes) -> tuple[str, str, float]:
    from .ocr import extract_image

    return extract_image(content)


def _extract_pdf(content: bytes) -> tuple[str, str, float]:
    import pymupdf

    with pymupdf.open(stream=content, filetype="pdf") as document:
        text = "\n".join(page.get_text("text") for page in document).strip()
        if len(text) >= 40:
            return text, "pdf_text", 0.99
        pages: list[str] = []
        confidences: list[float] = []
        for page in document:
            pixmap = page.get_pixmap(matrix=pymupdf.Matrix(2, 2), alpha=False)
            page_text, _, confidence = _ocr_image(pixmap.tobytes("png"))
            pages.append(page_text)
            confidences.append(confidence)
        return (
            "\n".join(pages),
            "paddleocr",
            (sum(confidences) / len(confidences) if confidences else 0.55),
        )


def extract_document_text(content: bytes, mime_type: str) -> tuple[str, str, float]:
    if mime_type == "application/pdf":
        return _extract_pdf(content)
    if (
        mime_type
        == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    ):
        return _extract_docx(content)
    if mime_type in {"image/jpeg", "image/png"}:
        return _ocr_image(content)
    raise ValueError(f"Unsupported document type: {mime_type}")


async def process_claim(
    gateway: FirebaseGateway,
    claim: dict[str, Any],
    actor_id: str,
) -> ProcessResult:
    claim_id = claim["id"]
    reference = claim["reference"]
    now = datetime.now(timezone.utc).isoformat()
    jobs = await gateway.records(
        "POST",
        "claim_processing_jobs",
        service=True,
        json={
            "claim_id": claim_id,
            "created_by": actor_id,
            "status": "RUNNING",
            "attempt_count": 1,
            "started_at": now,
        },
    )
    job_id = jobs[0]["id"]
    try:
        await gateway.records(
            "PATCH",
            "claims",
            service=True,
            params={"id": f"eq.{claim_id}"},
            json={"status": "PROCESSING"},
        )
        await gateway.records(
            "POST",
            "audit_events",
            service=True,
            json={
                "claim_id": claim_id,
                "actor_id": actor_id,
                "event_type": "PROCESSING_STARTED",
            },
        )
    except Exception as exc:
        error = str(exc)[:1000]
        await gateway.records(
            "PATCH",
            "claims",
            service=True,
            params={"id": f"eq.{claim_id}"},
            json={"status": "PROCESSING_FAILED"},
        )
        await gateway.records(
            "PATCH",
            "claim_processing_jobs",
            service=True,
            params={"id": f"eq.{job_id}"},
            json={
                "status": "FAILED",
                "last_error": error,
                "finished_at": datetime.now(timezone.utc).isoformat(),
            },
        )
        raise HTTPException(status_code=422, detail=error) from exc
    try:
        documents = await gateway.records(
            "GET",
            "claim_documents",
            service=True,
            params={"claim_id": f"eq.{claim_id}", "order": "created_at.asc"},
        )
        await gateway.records(
            "DELETE",
            "claim_extracted_fields",
            service=True,
            params={"claim_id": f"eq.{claim_id}"},
        )
        hashes: dict[str, str] = {}
        field_count = 0
        warning_count = 0
        for document in documents:
            content = await gateway.download(document["storage_path"])
            digest = hashlib.sha256(content).hexdigest()
            duplicate_of = hashes.get(digest)
            hashes.setdefault(digest, document["id"])
            try:
                text, method, confidence = await asyncio.to_thread(
                    extract_document_text, content, document["mime_type"]
                )
                if not text.strip():
                    raise ValueError(
                        "No readable text was found. Upload a clearer image or enter the values manually."
                    )
                document_type, _, payable = classify_document(text)
                fields, amount, currency, warnings = extract_fields(
                    TextDocument(document["id"], text, method, confidence)
                )
                warning_count += warnings + (1 if duplicate_of else 0)
                field_rows = [
                    {
                        "claim_id": claim_id,
                        "document_id": field.document_id,
                        "field_name": field.field_name,
                        "raw_value": field.raw_value,
                        "normalized_value": field.normalized_value,
                        "confidence": field.confidence,
                        "extraction_method": field.extraction_method,
                        "page_number": field.page_number,
                    }
                    for field in fields
                ]
                if field_rows:
                    await gateway.records(
                        "POST", "claim_extracted_fields", service=True, json=field_rows
                    )
                field_count += len(field_rows)
                amount_field = next(
                    (field for field in fields if field.field_name == "claimed_amount"),
                    None,
                )
                status = "COMPLETED" if amount and currency else "NEEDS_CONFIRMATION"
                notes = (
                    None
                    if amount
                    else "No reliable payable total was found; please enter the document amount."
                )
                await gateway.records(
                    "PATCH",
                    "claim_documents",
                    service=True,
                    params={"id": f"eq.{document['id']}"},
                    json={
                        "document_type": document_type,
                        "extracted_amount": amount,
                        "extracted_currency": currency,
                        "amount_confidence": amount_field.confidence
                        if amount_field
                        else None,
                        "include_in_total": bool(
                            payable and amount and not duplicate_of
                        ),
                        "duplicate_of": duplicate_of,
                        "extraction_status": status,
                        "extraction_notes": notes,
                        "extracted_at": now,
                    },
                )
            except Exception as exc:
                warning_count += 1
                await gateway.records(
                    "PATCH",
                    "claim_documents",
                    service=True,
                    params={"id": f"eq.{document['id']}"},
                    json={
                        "extraction_status": "FAILED",
                        "extraction_notes": str(exc)[:500],
                        "extracted_at": now,
                    },
                )

        await gateway.records(
            "PATCH",
            "claims",
            service=True,
            params={"id": f"eq.{claim_id}"},
            json={"status": "UPLOADED", "warning_count": warning_count},
        )
        await gateway.records(
            "PATCH",
            "claim_processing_jobs",
            service=True,
            params={"id": f"eq.{job_id}"},
            json={
                "status": "COMPLETED",
                "finished_at": datetime.now(timezone.utc).isoformat(),
            },
        )
        await gateway.records(
            "POST",
            "audit_events",
            service=True,
            json={
                "claim_id": claim_id,
                "actor_id": actor_id,
                "event_type": "PROCESSING_COMPLETED",
                "metadata": {"documents": len(documents), "fields": field_count},
            },
        )
        return ProcessResult(
            claim_reference=reference,
            status="UPLOADED",
            document_count=len(documents),
            extracted_field_count=field_count,
        )
    except Exception as exc:
        error = str(exc)[:1000]
        await gateway.records(
            "PATCH",
            "claims",
            service=True,
            params={"id": f"eq.{claim_id}"},
            json={"status": "PROCESSING_FAILED"},
        )
        await gateway.records(
            "PATCH",
            "claim_processing_jobs",
            service=True,
            params={"id": f"eq.{job_id}"},
            json={
                "status": "FAILED",
                "last_error": error,
                "finished_at": datetime.now(timezone.utc).isoformat(),
            },
        )
        await gateway.records(
            "POST",
            "audit_events",
            service=True,
            json={
                "claim_id": claim_id,
                "actor_id": actor_id,
                "event_type": "PROCESSING_FAILED",
                "metadata": {"error": error},
            },
        )
        raise HTTPException(status_code=422, detail=error) from exc
