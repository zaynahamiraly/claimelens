from types import SimpleNamespace
from unittest.mock import AsyncMock
from unittest.mock import Mock
import asyncio
import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from app.main import app
from app.routers import auth
from app.firebase import can_access_claim


@pytest.mark.parametrize(
    "role", ["administrator", "claims_officer", "supervisor", "client"]
)
def test_existing_profile_role_and_status_survive_login_profile_check(
    monkeypatch, role
):
    from app.firebase import FirebaseGateway
    from app import firebase

    existing = {
        "id": "existing",
        "role": role,
        "status": "inactive",
        "display_name": "Existing User",
    }
    snapshot = SimpleNamespace(exists=True, to_dict=lambda: dict(existing))
    reference = SimpleNamespace(get=lambda **kwargs: snapshot)
    transaction = Mock()
    store = FirebaseGateway.__new__(FirebaseGateway)
    store.db = SimpleNamespace(
        collection=lambda name: SimpleNamespace(document=lambda uid: reference),
        transaction=lambda: transaction,
    )
    monkeypatch.setattr(firebase.firestore, "transactional", lambda function: function)
    actual = asyncio.run(
        store.ensure_profile("existing", "New name", "existing@example.com")
    )
    assert actual == existing
    transaction.set.assert_not_called()
    transaction.update.assert_not_called()


def test_duplicate_signup_never_changes_staff_profile(monkeypatch):
    upstream = AsyncMock(
        side_effect=HTTPException(
            400, "An account already exists. Sign in or reset your password."
        )
    )
    gateway = Mock()
    monkeypatch.setattr(auth, "firebase_request", upstream)
    monkeypatch.setattr(auth, "FirebaseGateway", gateway)
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/auth/signup",
            json={
                "email": "admin@claimlens.com",
                "display_name": "Someone",
                "password": "long-password",
            },
        )
    assert response.status_code == 400
    gateway.assert_not_called()


def test_claim_access_is_scoped_by_role():
    claim = {"client_id": "owner", "assigned_to": "officer"}
    for uid, role, expected in [
        ("owner", "client", True),
        ("other", "client", False),
        ("officer", "claims_officer", True),
        ("other", "claims_officer", False),
        ("boss", "supervisor", True),
        ("admin", "administrator", True),
    ]:
        user = SimpleNamespace(id=uid, profile=SimpleNamespace(role=role))
        assert can_access_claim(user, claim) == expected


def test_signup_does_not_accept_client_supplied_role(monkeypatch):
    upstream = AsyncMock(
        return_value={"localId": "new-client", "idToken": "test-token"}
    )
    profile = AsyncMock()
    monkeypatch.setattr(auth, "firebase_request", upstream)
    monkeypatch.setattr(
        auth, "FirebaseGateway", lambda request: SimpleNamespace(ensure_profile=profile)
    )
    with TestClient(app) as client:
        result = client.post(
            "/api/v1/auth/signup",
            json={
                "email": "Client@example.com",
                "display_name": "Client",
                "password": "long-password",
                "role": "administrator",
            },
        )
    assert result.status_code == 200
    assert profile.call_args.args == ("new-client", "Client", "client@example.com")
    assert upstream.call_args_list[0].args[2]["email"] == "client@example.com"
    assert "role" not in upstream.call_args_list[0].args[2]
    assert "idToken" not in result.json()


def test_recovery_uses_firebase_hosted_link(monkeypatch):
    upstream = AsyncMock(return_value={})
    monkeypatch.setattr(auth, "firebase_request", upstream)
    with TestClient(app) as client:
        result = client.post(
            "/api/v1/auth/forgot-password", json={"email": "client@example.com"}
        )
    assert result.status_code == 200
    assert upstream.call_args.args[2]["requestType"] == "PASSWORD_RESET"
    assert "link" in result.json()["message"]


def test_password_validation_precedes_network(monkeypatch):
    upstream = AsyncMock()
    monkeypatch.setattr(auth, "firebase_request", upstream)
    with TestClient(app) as client:
        result = client.post(
            "/api/v1/auth/signup",
            json={
                "email": "client@example.com",
                "display_name": "Client",
                "password": "short",
            },
        )
    assert result.status_code == 422
    upstream.assert_not_called()


def test_invalid_firebase_token_is_rejected(monkeypatch):
    from app import security

    monkeypatch.setattr(security, "firebase_app", lambda: None)
    monkeypatch.setattr(
        security.auth,
        "verify_id_token",
        lambda *a, **kw: (_ for _ in ()).throw(ValueError("bad token")),
    )
    with TestClient(app) as client:
        response = client.get(
            "/api/v1/profile", headers={"Authorization": "Bearer invalid"}
        )
    assert response.status_code == 401
