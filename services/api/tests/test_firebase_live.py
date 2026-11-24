"""Opt-in live check with disposable accounts and a generated Word invoice.

RUN_FIREBASE_LIVE_TESTS=1 enables writes to the configured Firebase project.
Only records created by this test are removed afterward. No emails are sent.
"""

import io
import os
import uuid
import pytest

pytestmark = pytest.mark.skipif(
    os.getenv("RUN_FIREBASE_LIVE_TESTS") != "1", reason="Live Firebase check is opt-in"
)


def test_live_login_private_upload_processing_and_confirmation():
    from docx import Document
    from fastapi.testclient import TestClient
    from firebase_admin import auth, firestore
    from google.cloud.firestore_v1.base_query import FieldFilter
    from app.firebase import firebase_app
    from app.documents import document_store
    from app.main import app

    fb = firebase_app()
    db = firestore.client(fb)
    users = []
    claim_id = None
    try:
        for _ in range(5):
            users.append(
                auth.create_user(
                    email=f"claimelens-test-{uuid.uuid4().hex}@example.com",
                    password="Synthetic-check-291!",
                    app=fb,
                )
            )
        with TestClient(app) as client:
            headers = []
            refresh_token = None
            for user in users:
                response = client.post(
                    "/api/v1/auth/login",
                    json={"email": user.email, "password": "Synthetic-check-291!"},
                )
                assert response.status_code == 200, response.text
                assert response.json()["user"]["role"] == "client"
                headers.append(
                    {"Authorization": "Bearer " + response.json()["access_token"]}
                )
                refresh_token = response.json()["refresh_token"]
            assert (
                client.post(
                    "/api/v1/auth/refresh", json={"refresh_token": refresh_token}
                ).status_code
                == 200
            )
            assert client.get("/api/v1/profile", headers=headers[0]).status_code == 200
            invoice = Document()
            for line in [
                "TEST MEDICAL CLINIC",
                "INVOICE",
                "Patient name: Synthetic Person",
                "Total: MUR 1250.00",
            ]:
                invoice.add_paragraph(line)
            output = io.BytesIO()
            invoice.save(output)
            response = client.post(
                "/api/v1/claims",
                headers=headers[0],
                files={
                    "files": (
                        "invoice.docx",
                        output.getvalue(),
                        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                    )
                },
            )
            assert response.status_code == 201, response.text
            data = response.json()
            claim_id = data["id"]
            url = "/api/v1/claims/" + data["reference"]
            assert client.get(url, headers=headers[1]).status_code == 404
            assert client.post(url + "/process", headers=headers[1]).status_code == 404
            response = client.post(url + "/process", headers=headers[0])
            assert response.status_code == 200, response.text
            assert response.json()["extracted_field_count"] > 0
            details = client.get(url, headers=headers[0])
            assert details.status_code == 200, details.text
            document = details.json()["documents"][0]
            assert float(document["extracted_amount"]) == 1250
            link = document["signed_url"].replace("http://127.0.0.1:8000", "")
            downloaded = client.get(link)
            assert downloaded.status_code == 200
            assert downloaded.content == output.getvalue()
            assert client.get(link + "tampered").status_code == 403
            payload = {
                "patient_name": "Synthetic Person",
                "provider_name": "Test Medical Clinic",
                "documents": [
                    {
                        "id": document["id"],
                        "include": True,
                        "amount": "1250.00",
                        "currency": "MUR",
                    }
                ],
            }
            assert (
                client.post(
                    url + "/confirm", headers=headers[1], json=payload
                ).status_code
                == 404
            )
            result = client.post(url + "/confirm", headers=headers[0], json=payload)
            assert result.status_code == 200, result.text
            assert result.json()["status"] == "REVIEW_REQUIRED"
            assert client.post(
                url + "/confirm", headers=headers[0], json=payload
            ).status_code in (403, 409)
            assert (
                db.collection("claims")
                .document(claim_id)
                .get()
                .to_dict()["claimed_amount"]
                == "1250.00"
            )
            # Elevate only this test's disposable accounts, never real staff.
            for account, role in zip(
                users[2:], ["claims_officer", "supervisor", "administrator"]
            ):
                db.collection("profiles").document(account.uid).update({"role": role})
            owner, stranger, officer, supervisor, administrator = headers
            db.collection("profiles").document(users[3].uid).update(
                {"permissions": ["payments.record"]}
            )
            assert client.get("/api/v1/users", headers=officer).status_code == 403
            assert client.get("/api/v1/users", headers=administrator).status_code == 200
            assert (
                client.post(
                    url + "/actions/verify", headers=officer, json={}
                ).status_code
                == 403
            )
            assert (
                client.post(
                    url + "/actions/claim", headers=officer, json={}
                ).status_code
                == 200
            )
            result = client.post(
                url + "/actions/request-information",
                headers=officer,
                json={
                    "reason": "Need itemized evidence",
                    "questions": "Please explain the treatment and send an itemized receipt.",
                    "internal_note": "Private synthetic staff note",
                },
            )
            assert result.status_code == 200, result.text
            details = client.get(url, headers=owner).json()
            request_id = details["information_requests"][0]["id"]
            assert "internal_note" not in details["information_requests"][0]
            assert (
                client.get(url, headers=officer).json()["information_requests"][0][
                    "internal_note"
                ]
                == "Private synthetic staff note"
            )
            response_path = url + "/information/" + request_id + "/respond"
            assert (
                client.post(
                    response_path,
                    headers=stranger,
                    data={"response_text": "Forged response"},
                ).status_code
                == 404
            )
            result = client.post(
                response_path,
                headers=owner,
                data={"response_text": "The treatment was a consultation."},
                files={
                    "files": (
                        "additional.docx",
                        output.getvalue(),
                        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                    )
                },
            )
            assert result.status_code == 200, result.text
            assert (
                client.post(
                    response_path,
                    headers=owner,
                    data={"response_text": "Duplicate response"},
                ).status_code
                == 403
            )
            details = client.get(url, headers=officer).json()
            assert details["status"] == "INFORMATION_RECEIVED"
            assert details["workflow"]["needs_reconfirmation"] is True
            assert (
                client.post(
                    url + "/actions/verify", headers=officer, json={}
                ).status_code
                == 422
            )
            payload["documents"] = [
                {
                    "id": row["id"],
                    "include": row["id"] == document["id"],
                    "amount": "1250.00" if row["id"] == document["id"] else None,
                    "currency": "MUR",
                }
                for row in details["documents"]
            ]
            result = client.post(
                url + "/actions/correct", headers=officer, json=payload
            )
            assert result.status_code == 200, result.text
            assert (
                client.post(
                    url + "/actions/verify", headers=officer, json={}
                ).status_code
                == 200
            )
            assert (
                client.post(
                    url + "/actions/approve",
                    headers=officer,
                    json={"notes": "Not authorized", "approved_amount": "1000.00"},
                ).status_code
                == 403
            )
            assert client.get(url + '/receipt', headers=owner).content.startswith(b'%PDF-')
            assert client.get(url + '/receipt/preview', headers=owner).headers['content-type'].startswith('image/png')
            assert client.get(url + '/documents/' + document['id'] + '/preview', headers=owner).status_code == 200
            rejected = client.post(url + '/actions/reject', headers=supervisor, json={'notes': 'Synthetic decision to exercise the appeal workflow'})
            assert rejected.status_code == 200, rejected.text
            assert client.post(url + '/appeal', headers=stranger, json={'reason': 'Another person’s claim is not mine'}).status_code == 404
            appealed = client.post(url + '/appeal', headers=owner, json={'reason': 'Please reconsider the original evidence for this synthetic claim.'})
            assert appealed.status_code == 200, appealed.text
            assert client.post(url + '/appeal', headers=owner, json={'reason': 'Duplicate appeal request'}).status_code == 409
            assert client.post(url + '/actions/claim', headers=officer, json={}).status_code == 200
            assert client.post(url + '/actions/verify', headers=officer, json={}).status_code == 200
            result = client.post(
                url + "/actions/approve",
                headers=supervisor,
                json={
                    "notes": "Evidence and coverage checked",
                    "approved_amount": "1000.00",
                },
            )
            assert result.status_code == 200, result.text
            assert (
                client.post(
                    url + "/actions/paid", headers=supervisor, json={}
                ).status_code
                == 403
            )
            assert (
                client.post(
                    url + "/actions/payment-pending", headers=supervisor, json={}
                ).status_code
                == 200
            )
            assert (
                client.post(
                    url + "/actions/paid",
                    headers=supervisor,
                    json={
                        "payment_reference": "SYNTHETIC-BANK-001",
                        "payment_method": "bank_transfer",
                    },
                ).status_code
                == 200
            )
            assert client.get(url, headers=owner).json()["status"] == "PAID"
            notices = client.get("/api/v1/notifications", headers=owner).json()
            assert notices
            notice_id = next(n["id"] for n in notices if n["claim_id"] == claim_id)
            assert (
                client.post(
                    "/api/v1/notifications/" + notice_id + "/read", headers=stranger
                ).status_code
                == 404
            )
            assert (
                client.post(
                    "/api/v1/notifications/" + notice_id + "/read", headers=owner
                ).status_code
                == 200
            )
            assert (
                client.get(
                    "/api/v1/workspace/analytics", headers=supervisor
                ).status_code
                == 200
            )
            assert (
                client.get("/api/v1/workspace/audit", headers=officer).status_code
                == 200
            )
            result = client.put(
                "/api/v1/profile",
                headers=owner,
                json={
                    "display_name": "Updated Test Client",
                    "phone": "1234567",
                    "theme": "dark",
                    "notifications_enabled": False,
                    "role": "administrator",
                },
            )
            assert result.status_code == 200, result.text
            assert result.json()["role"] == "client"
            assert result.json()["theme"] == "dark"
            assert (
                client.put(
                    "/api/v1/users/" + users[4].uid,
                    headers=administrator,
                    json={
                        "display_name": "Test Admin",
                        "role": "client",
                        "status": "active",
                    },
                ).status_code
                == 422
            )
            assert (
                client.delete(
                    "/api/v1/users/" + users[4].uid, headers=administrator
                ).status_code
                == 422
            )
    finally:
        if claim_id:
            for collection in [
                "claim_documents",
                "claim_extracted_fields",
                "claim_processing_jobs",
                "audit_events",
                "notifications",
                "claim_information_requests",
                "claim_appeals",
                "document_fingerprints",
            ]:
                for document in (
                    db.collection(collection)
                    .where(filter=FieldFilter("claim_id", "==", claim_id))
                    .stream()
                ):
                    path = document.to_dict().get("storage_path")
                    if path:
                        document_store().delete(path)
                    document.reference.delete()
            db.collection("claims").document(claim_id).delete()
        for user in users:
            db.collection("profiles").document(user.uid).delete()
            auth.delete_user(user.uid, app=fb)
