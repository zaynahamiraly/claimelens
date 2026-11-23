from types import SimpleNamespace
from datetime import date, timedelta
from decimal import Decimal

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.main import app
from app.security import get_current_user
from app.workflow import WorkflowInput, available_actions, workflow_patch
from app.firebase import can_access_claim
from unittest.mock import AsyncMock


def user(role, uid="officer"):
    return SimpleNamespace(id=uid, profile=SimpleNamespace(role=role))


def claim(status="REVIEW_REQUIRED", **values):
    return {
        "status": status,
        "assigned_to": "officer",
        "patient_name": "Test Person",
        "provider_name": "Test Clinic",
        "claimed_amount": "1250.00",
        **values,
    }


@pytest.mark.parametrize("role", ["client", "claims_officer"])
@pytest.mark.parametrize(
    "action,status",
    [
        ("approve", "VERIFIED"),
        ("reject", "VERIFIED"),
        ("payment-pending", "APPROVED"),
        ("paid", "PAYMENT_PENDING"),
    ],
)
def test_only_management_can_decide_and_record_payment(role, action, status):
    with pytest.raises(HTTPException) as error:
        workflow_patch(
            user(role),
            claim(status),
            action,
            WorkflowInput(notes="Checked source", approved_amount=1250),
        )
    assert error.value.status_code == 403


def test_officer_must_take_assignment_before_reviewing():
    reviewer = user("claims_officer")
    assert available_actions(reviewer, claim(assigned_to=None)) == ["claim"]
    assert available_actions(reviewer, claim(assigned_to="someone-else")) == []
    assert "verify" in available_actions(reviewer, claim())
    assert can_access_claim(reviewer, claim(assigned_to=None))
    assert not can_access_claim(reviewer, claim("UPLOADED", assigned_to=None))


def test_verified_claim_follows_decision_and_settlement_sequence():
    manager = user("supervisor")
    current = claim("VERIFIED")
    patch, event = workflow_patch(
        manager,
        current,
        "approve",
        WorkflowInput(notes="Evidence checked", approved_amount=Decimal("1100.00")),
    )
    assert event == "CLAIM_APPROVED"
    assert patch["approved_amount"] == "1100.00"
    with pytest.raises(HTTPException):
        workflow_patch(manager, {**current, **patch}, "paid", WorkflowInput())
    patch, _ = workflow_patch(
        manager, {**current, **patch}, "payment-pending", WorkflowInput()
    )
    patch, _ = workflow_patch(manager, {**current, **patch}, "paid", WorkflowInput())
    assert patch["status"] == "PAID"
    assert patch["paid_at"]


@pytest.mark.parametrize("amount", ["1250.01", None])
def test_approval_cannot_exceed_claim_total_or_omit_amount(amount):
    with pytest.raises(HTTPException) as error:
        workflow_patch(
            user("administrator"),
            claim("VERIFIED"),
            "approve",
            WorkflowInput(notes="Evidence checked", approved_amount=amount),
        )
    assert error.value.status_code == 422


@pytest.mark.parametrize(
    "change",
    [
        {"needs_reconfirmation": True},
        {"patient_name": ""},
        {"claimed_amount": "0"},
        {"provider_name": ""},
    ],
)
def test_verification_requires_reviewed_identity_and_payable_amount(change):
    with pytest.raises(HTTPException) as error:
        workflow_patch(
            user("claims_officer"), claim(**change), "verify", WorkflowInput()
        )
    assert error.value.status_code == 422


def test_information_request_requires_clear_questions_and_future_deadline():
    reviewer = user("claims_officer")
    with pytest.raises(HTTPException):
        workflow_patch(reviewer, claim(), "request-information", WorkflowInput())
    with pytest.raises(HTTPException):
        workflow_patch(
            reviewer,
            claim(),
            "request-information",
            WorkflowInput(
                reason="Missing evidence",
                questions="Please send a receipt",
                response_deadline=date.today() - timedelta(days=2),
            ),
        )
    patch, _ = workflow_patch(
        reviewer,
        claim(),
        "request-information",
        WorkflowInput(reason="Missing evidence", questions="Please send a receipt"),
    )
    assert patch["status"] == "INFORMATION_REQUIRED"
    assert available_actions(user("client"), claim("INFORMATION_REQUIRED")) == [
        "respond"
    ]


def test_background_processing_returns_status_for_mobile_polling(monkeypatch):
    from app.routers import claims as routes

    current = {"id": "test-claim", "reference": "CLM-TEST", "status": "UPLOADED"}
    gateway = SimpleNamespace(acquire_processing=AsyncMock())
    processor = AsyncMock()
    monkeypatch.setattr(routes, "FirebaseGateway", lambda request: gateway)
    monkeypatch.setattr(routes, "accessible_claim", AsyncMock(return_value=current))
    monkeypatch.setattr(routes, "process_claim", processor)
    app.dependency_overrides[get_current_user] = lambda: user("client")
    try:
        with TestClient(app) as client:
            result = client.post("/api/v1/claims/CLM-TEST/process?background=true")
        assert result.status_code == 200
        assert result.json()["status"] == "PROCESSING"
        gateway.acquire_processing.assert_awaited_once_with("test-claim")
        processor.assert_awaited_once()
    finally:
        app.dependency_overrides.clear()


@pytest.mark.parametrize(
    "path",
    ["/users", "/workspace/analytics", "/workspace/audit", "/workspace/officers"],
)
def test_clients_cannot_open_staff_workspace_endpoints(path):
    app.dependency_overrides[get_current_user] = lambda: user("client")
    try:
        with TestClient(app) as client:
            assert client.get("/api/v1" + path).status_code == 403
    finally:
        app.dependency_overrides.clear()


@pytest.mark.parametrize("role", ["claims_officer", "supervisor"])
def test_staff_cannot_create_admin_accounts(role):
    app.dependency_overrides[get_current_user] = lambda: user(role)
    try:
        with TestClient(app) as client:
            response = client.post(
                "/api/v1/users",
                json={
                    "display_name": "Someone",
                    "email": "new@example.com",
                    "password": "Synthetic-only-123!",
                    "role": "administrator",
                },
            )
            assert response.status_code == 403
    finally:
        app.dependency_overrides.clear()
