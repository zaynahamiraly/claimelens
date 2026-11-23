"""Role-aware claim workflow shared by the API and its regression tests."""

import asyncio
from datetime import date, datetime
from decimal import Decimal
from zoneinfo import ZoneInfo

from fastapi import HTTPException
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from pydantic import BaseModel, Field, field_validator
from .schemas import DocumentConfirmation, FieldCorrection

from .firebase import can_access_claim, now

STAFF = {"claims_officer", "supervisor", "administrator"}
MANAGEMENT = {"supervisor", "administrator"}
REVIEWABLE = {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"}


class WorkflowInput(BaseModel):
    assignee: str | None = None
    notes: str = Field(default="", max_length=2000)
    approved_amount: Decimal | None = Field(
        default=None, gt=0, max_digits=14, decimal_places=2
    )
    patient_name: str | None = Field(default=None, min_length=2, max_length=200)
    provider_name: str | None = Field(default=None, min_length=2, max_length=200)
    reason: str = Field(default="", max_length=500)
    questions: str = Field(default="", max_length=2000)
    required_documents: str = Field(default="", max_length=1000)
    response_deadline: date | None = None
    internal_note: str = Field(default="", max_length=2000)
    documents: list[dict] = Field(default_factory=list, max_length=10)
    fields: list[dict] = Field(default_factory=list, max_length=100)

    @field_validator("documents", mode="before")
    @classmethod
    def checked_documents(cls, values):
        return [
            DocumentConfirmation.model_validate(value).model_dump(mode="json")
            for value in values
        ]

    @field_validator("fields", mode="before")
    @classmethod
    def checked_fields(cls, values):
        return [
            FieldCorrection.model_validate(value).model_dump(mode="json")
            for value in values
        ]


def available_actions(user, claim):
    role = user.profile.role
    status = claim["status"]
    result = []
    if role == "client":
        if status == "INFORMATION_REQUIRED":
            result.append("respond")
        return result
    if role not in STAFF:
        return result
    assigned = claim.get("assigned_to")
    if status in REVIEWABLE:
        if role in MANAGEMENT:
            result.append("assign")
        elif assigned is None:
            result.append("claim")
        if role in MANAGEMENT or assigned == user.id:
            result += ["correct", "verify", "request-information"]
    if role in MANAGEMENT and status == "VERIFIED":
        result += ["approve", "reject"]
    if role in MANAGEMENT and status == "APPROVED":
        result.append("payment-pending")
    if role in MANAGEMENT and status == "PAYMENT_PENDING":
        result.append("paid")
    return result


def workflow_patch(user, claim, action, payload):
    if action not in available_actions(user, claim):
        raise HTTPException(
            403,
            "This action is not available for your role or the current claim status.",
        )
    patch = {"updated_at": now()}
    event = ""
    if action in {"assign", "claim"}:
        assignee = user.id if action == "claim" else payload.assignee
        if not assignee:
            raise HTTPException(422, "Choose an active claims officer.")
        patch["assigned_to"] = assignee
        event = "CLAIM_ASSIGNED"
    elif action == "correct":
        if (
            not payload.patient_name
            or not payload.patient_name.strip()
            or not payload.provider_name
            or not payload.provider_name.strip()
        ):
            raise HTTPException(422, "Enter patient and provider names.")
        patch.update(
            patient_name=payload.patient_name.strip(),
            provider_name=payload.provider_name.strip(),
            needs_reconfirmation=False,
            status="REVIEW_REQUIRED",
        )
        event = "CLAIM_CORRECTED"
    elif action == "verify":
        if (
            not claim.get("patient_name")
            or not claim.get("provider_name")
            or Decimal(str(claim.get("claimed_amount") or 0)) <= 0
            or claim.get("needs_reconfirmation")
        ):
            raise HTTPException(
                422,
                "Review the patient, provider, and document amounts before verifying.",
            )
        patch.update(status="VERIFIED", verified_by=user.id, verified_at=now())
        event = "CLAIM_VERIFIED"
    elif action in {"approve", "reject"}:
        if len(payload.notes.strip()) < 5:
            raise HTTPException(422, "Enter decision notes of at least 5 characters.")
        if action == "approve" and (
            payload.approved_amount is None
            or payload.approved_amount > Decimal(str(claim.get("claimed_amount") or 0))
        ):
            raise HTTPException(
                422,
                "Approved amount must be positive and no greater than the claim total.",
            )
        patch.update(
            status="APPROVED" if action == "approve" else "REJECTED",
            decision_notes=payload.notes.strip(),
            approved_amount=str(payload.approved_amount)
            if action == "approve"
            else None,
            decided_by=user.id,
            decided_at=now(),
        )
        event = "CLAIM_" + patch["status"]
    elif action in {"payment-pending", "paid"}:
        patch.update(
            status="PAYMENT_PENDING" if action == "payment-pending" else "PAID"
        )
        if action == "paid":
            patch["paid_at"] = now()
        event = "CLAIM_" + patch["status"]
    elif action == "request-information":
        if len(payload.reason.strip()) < 5 or len(payload.questions.strip()) < 5:
            raise HTTPException(
                422, "Enter a clear reason and questions of at least 5 characters."
            )
        if (
            payload.response_deadline
            and payload.response_deadline
            < datetime.now(ZoneInfo("Indian/Mauritius")).date()
        ):
            raise HTTPException(422, "The response deadline cannot be in the past.")
        patch.update(status="INFORMATION_REQUIRED")
        event = "INFORMATION_REQUESTED"
    return patch, event


def write_event(db, transaction, claim, actor, event, metadata=None, watchers=()):
    ref = db.collection("audit_events").document()
    transaction.set(
        ref,
        {
            "id": ref.id,
            "claim_id": claim["id"],
            "actor_id": actor,
            "event_type": event,
            "metadata": metadata or {},
            "created_at": now(),
        },
    )
    for uid in (
        ({claim.get("client_id"), claim.get("assigned_to"), *watchers} - {None})
        if event != "FIELD_CORRECTED"
        else []
    ):
        notice = db.collection("notifications").document()
        transaction.set(
            notice,
            {
                "id": notice.id,
                "recipient_id": uid,
                "claim_id": claim["id"],
                "reference": claim["reference"],
                "title": event.replace("_", " ").title(),
                "body": f"{claim['reference']} has an update. Open the claim to see the details.",
                "read": False,
                "created_at": now(),
            },
        )


async def apply_action(gateway, claim_id, action, payload):
    user = gateway._user()
    db = gateway.db
    ref = db.collection("claims").document(claim_id)

    @firestore.transactional
    def run(transaction):
        snapshot = ref.get(transaction=transaction)
        claim = snapshot.to_dict() if snapshot.exists else None
        if not claim or not can_access_claim(user, claim):
            raise HTTPException(404, "Claim not found.")
        patch, event = workflow_patch(user, claim, action, payload)
        watchers = []
        if action == "verify":
            watchers = [
                snapshot.id
                for snapshot in db.collection("profiles")
                .where(
                    filter=FieldFilter("role", "in", ["supervisor", "administrator"])
                )
                .stream(transaction=transaction)
                if snapshot.to_dict().get("status") == "active"
            ]
        docs = []
        fields = []
        if action in {"assign", "claim"}:
            assignee = (
                db.collection("profiles")
                .document(patch["assigned_to"])
                .get(transaction=transaction)
            )
            if (
                not assignee.exists
                or assignee.to_dict().get("role") != "claims_officer"
                or assignee.to_dict().get("status") != "active"
            ):
                raise HTTPException(422, "Choose an active claims officer.")
        if action == "correct":
            docs = list(
                db.collection("claim_documents")
                .where(filter=FieldFilter("claim_id", "==", claim_id))
                .stream(transaction=transaction)
            )
            fields = list(
                db.collection("claim_extracted_fields")
                .where(filter=FieldFilter("claim_id", "==", claim_id))
                .stream(transaction=transaction)
            )
            if payload.documents:
                by_id = {d.id: d for d in docs}
                if len(payload.documents) != len(by_id) or {
                    d.get("id") for d in payload.documents
                } != set(by_id):
                    raise HTTPException(422, "Review every document exactly once.")
                total = Decimal("0")
                currencies = set()
                for item in payload.documents:
                    if item.get("include") is True:
                        try:
                            amount = Decimal(str(item.get("amount")))
                        except Exception:
                            raise HTTPException(422, "Enter valid document amounts.")
                        currency = str(item.get("currency", "")).upper()
                        if (
                            not amount.is_finite()
                            or amount <= 0
                            or amount.as_tuple().exponent < -2
                            or len(currency) != 3
                            or by_id[item["id"]].to_dict().get("duplicate_of")
                        ):
                            raise HTTPException(
                                422,
                                "Included documents need valid amounts, currencies, and must not be duplicates.",
                            )
                        total += amount
                        currencies.add(currency)
                if total <= 0 or len(currencies) != 1:
                    raise HTTPException(
                        422, "Include payable documents in one currency."
                    )
                patch.update(claimed_amount=str(total), currency=next(iter(currencies)))
            elif claim.get("needs_reconfirmation"):
                raise HTTPException(
                    422,
                    "Review every document amount after additional files were received.",
                )
            by_field = {f.id: f for f in fields}
            if len({f.get("id") for f in payload.fields}) != len(payload.fields):
                raise HTTPException(422, "Duplicate corrected fields.")
            for item in payload.fields:
                if (
                    item.get("id") not in by_field
                    or not str(item.get("value", "")).strip()
                ):
                    raise HTTPException(
                        422,
                        "Corrected field does not belong to this claim or has an empty value.",
                    )
        if action == "correct":
            for item in payload.documents:
                document = next(d for d in docs if d.id == item["id"])
                transaction.update(
                    document.reference,
                    {
                        "include_in_total": item.get("include") is True,
                        "confirmed_amount": str(item["amount"])
                        if item.get("include") is True
                        else None,
                        "confirmed_currency": str(item.get("currency", "")).upper()
                        if item.get("include") is True
                        else None,
                    },
                )
            by_field = {f.id: f for f in fields}
            for item in payload.fields:
                old = by_field[item["id"]]
                transaction.update(
                    old.reference,
                    {
                        "normalized_value": str(item["value"]).strip(),
                        "confidence": 0,
                        "extraction_method": "staff_corrected",
                    },
                )
                write_event(
                    db,
                    transaction,
                    claim,
                    user.id,
                    "FIELD_CORRECTED",
                    {
                        "field_name": old.to_dict().get("field_name"),
                        "previous_value": old.to_dict().get("normalized_value"),
                        "corrected_value": str(item["value"]).strip(),
                    },
                )
        if action == "request-information":
            info = db.collection("claim_information_requests").document()
            transaction.set(
                info,
                {
                    "id": info.id,
                    "claim_id": claim_id,
                    "requested_by": user.id,
                    "reason": payload.reason.strip(),
                    "questions": payload.questions.strip(),
                    "required_documents": payload.required_documents.strip(),
                    "response_deadline": payload.response_deadline.isoformat()
                    if payload.response_deadline
                    else None,
                    "internal_note": payload.internal_note.strip(),
                    "status": "OPEN",
                    "created_at": now(),
                },
            )
        transaction.update(ref, patch)
        write_event(
            db,
            transaction,
            {**claim, **patch},
            user.id,
            event,
            {
                "notes": payload.notes.strip(),
                "assignee": patch.get("assigned_to"),
                "approved_amount": patch.get("approved_amount"),
            },
            watchers=watchers,
        )
        return {**claim, **patch}

    return await asyncio.to_thread(run, db.transaction())


async def workflow_details(gateway, claim):
    def load():
        rows = [
            s.to_dict()
            for s in gateway.db.collection("claim_information_requests")
            .where(filter=FieldFilter("claim_id", "==", claim["id"]))
            .stream()
        ]
        rows.sort(key=lambda row: row.get("created_at", ""), reverse=True)
        if gateway._user().profile.role == "client":
            for row in rows:
                row.pop("internal_note", None)
        workflow = {
            key: claim.get(key)
            for key in (
                "client_id",
                "assigned_to",
                "verified_by",
                "verified_at",
                "decision_notes",
                "approved_amount",
                "decided_at",
                "paid_at",
                "needs_reconfirmation",
            )
        }
        for key, label in [
            ("client_id", "client_name"),
            ("assigned_to", "assigned_officer_name"),
        ]:
            profile = (
                gateway.db.collection("profiles").document(claim[key]).get()
                if claim.get(key)
                else None
            )
            workflow[label] = (
                profile.to_dict().get("display_name")
                if profile and profile.exists
                else None
            )
        return {
            "available_actions": available_actions(gateway._user(), claim),
            "information_requests": rows,
            "workflow": workflow,
        }

    return await asyncio.to_thread(load)
