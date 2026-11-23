"""Opt-in disposable-account checks. No emails or real account changes."""

import os
import uuid
import pytest

pytestmark = pytest.mark.skipif(
    os.getenv("RUN_FIREBASE_LIVE_TESTS") != "1", reason="Live Firebase check is opt-in"
)


def test_live_administrator_access_and_account_settings():
    from fastapi.testclient import TestClient
    from firebase_admin import auth, firestore
    from google.cloud.firestore_v1.base_query import FieldFilter
    from app.firebase import firebase_app
    from app.main import app

    fb = firebase_app()
    db = firestore.client(fb)
    owned = []
    initial = "Synthetic-only-291!"
    try:
        admin = auth.create_user(
            email=f"claimelens-admin-test-{uuid.uuid4().hex}@example.com",
            password=initial,
            app=fb,
        )
        owned.append(admin.uid)
        with TestClient(app) as client:
            login = client.post(
                "/api/v1/auth/login", json={"email": admin.email, "password": initial}
            )
            assert login.status_code == 200, login.text
            db.collection("profiles").document(admin.uid).update(
                {"role": "administrator"}
            )
            headers = {"Authorization": "Bearer " + login.json()["access_token"]}
            email = f"claimelens-account-test-{uuid.uuid4().hex}@example.com"
            created = client.post(
                "/api/v1/users",
                headers=headers,
                json={
                    "display_name": "Temporary Officer",
                    "email": email,
                    "password": initial,
                    "role": "claims_officer",
                },
            )
            assert created.status_code == 201, created.text
            uid = created.json()["id"]
            owned.append(uid)
            assert (
                client.post(
                    "/api/v1/users",
                    headers=headers,
                    json={
                        "display_name": "Duplicate",
                        "email": email,
                        "password": initial,
                        "role": "client",
                    },
                ).status_code
                == 409
            )
            signed_in = client.post(
                "/api/v1/auth/login", json={"email": email, "password": initial}
            )
            assert signed_in.json()["user"]["role"] == "claims_officer"
            officer = {"Authorization": "Bearer " + signed_in.json()["access_token"]}
            edit = {
                "display_name": "Updated Officer",
                "role": "claims_officer",
                "status": "inactive",
            }
            assert (
                client.put(
                    "/api/v1/users/" + uid, headers=headers, json=edit
                ).status_code
                == 200
            )
            assert client.get("/api/v1/profile", headers=officer).status_code == 403
            edit["status"] = "active"
            assert (
                client.put(
                    "/api/v1/users/" + uid, headers=headers, json=edit
                ).status_code
                == 200
            )
            assert (
                client.get("/api/v1/profile", headers=officer).json()["display_name"]
                == "Updated Officer"
            )
            reset = client.post(
                "/api/v1/users/" + uid + "/password-reset", headers=headers
            )
            assert reset.status_code == 200
            assert reset.json()["link"].startswith("https://")
            wrong = client.post(
                "/api/v1/profile/password",
                headers=officer,
                json={
                    "current_password": "Wrong-password",
                    "new_password": "Changed-synthetic-987!",
                },
            )
            assert wrong.status_code == 400
            changed = client.post(
                "/api/v1/profile/password",
                headers=officer,
                json={
                    "current_password": initial,
                    "new_password": "Changed-synthetic-987!",
                },
            )
            assert changed.status_code == 200, changed.text
            assert changed.json()["user"]["role"] == "claims_officer"
            assert (
                client.post(
                    "/api/v1/auth/login",
                    json={"email": email, "password": "Changed-synthetic-987!"},
                ).status_code
                == 200
            )
            assert (
                client.delete("/api/v1/users/" + uid, headers=headers).status_code
                == 200
            )
            assert (
                db.collection("profiles").document(uid).get().to_dict()["deleted"]
                is True
            )
    finally:
        for uid in owned:
            for event in (
                db.collection("audit_events")
                .where(filter=FieldFilter("metadata.target_user_id", "==", uid))
                .stream()
            ):
                event.reference.delete()
            db.collection("profiles").document(uid).delete()
            try:
                auth.delete_user(uid, app=fb)
            except auth.UserNotFoundError:
                pass
