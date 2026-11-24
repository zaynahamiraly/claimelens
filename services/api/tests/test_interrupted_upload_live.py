"""Abort a real HTTPS multipart transfer, then retry without orphan/duplicate claims."""

import os
import socket
import ssl
import time
import uuid
from urllib.parse import urlparse
import pytest

pytestmark = pytest.mark.skipif(
    os.getenv("RUN_PUBLIC_API_TESTS") != "1", reason="Live public API opt-in required"
)


def test_connection_cut_mid_upload_then_same_key_retry():
    import httpx
    import pymupdf
    from firebase_admin import auth, firestore
    from google.cloud.firestore_v1.base_query import FieldFilter
    from app.firebase import firebase_app
    from app.documents import document_store
    from app.config import get_settings

    endpoint = get_settings().public_api_url
    assert endpoint.startswith("https://")
    fb = firebase_app()
    db = firestore.client(fb)
    account = auth.create_user(
        email=f"claimlens-network-{uuid.uuid4().hex}@example.com",
        password="Synthetic-upload-2026!",
        app=fb,
    )
    claim_id = None
    try:
        with httpx.Client(base_url=endpoint, timeout=60) as client:
            login = client.post(
                "/api/v1/auth/login",
                json={"email": account.email, "password": "Synthetic-upload-2026!"},
            )
            assert login.status_code == 200, login.text
            client.headers["Authorization"] = "Bearer " + login.json()["access_token"]
            with pymupdf.open() as d:
                p = d.new_page()
                p.insert_text((40, 80), "SYNTHETIC NETWORK TEST INVOICE - MUR 100")
                content = d.tobytes() + b"\n% synthetic-padding\n" * 12000
            key = uuid.uuid4().hex
            files = {"files": ("network-test.pdf", content, "application/pdf")}
            request = client.build_request(
                "POST", "/api/v1/claims", files=files, headers={"Idempotency-Key": key}
            )
            body = request.read()
            parsed = urlparse(endpoint)
            with socket.create_connection((parsed.hostname, 443), timeout=20) as raw:
                with ssl.create_default_context().wrap_socket(
                    raw, server_hostname=parsed.hostname
                ) as connection:
                    headers = "\r\n".join(
                        f"{name}: {value}" for name, value in request.headers.items()
                    )
                    connection.sendall(
                        f"POST /api/v1/claims HTTP/1.1\r\n{headers}\r\n\r\n".encode()
                        + body[:2048]
                    )
                    # Close before the declared Content-Length has been sent.
            time.sleep(1)
            listing = client.get("/api/v1/claims")
            assert listing.status_code == 200, listing.text
            assert listing.json() == []
            retried = client.post(
                "/api/v1/claims", files=files, headers={"Idempotency-Key": key}
            )
            assert retried.status_code == 201, retried.text
            claim_id = retried.json()["id"]
            replay = client.post(
                "/api/v1/claims", files=files, headers={"Idempotency-Key": key}
            )
            assert replay.status_code == 201 and replay.json()["id"] == claim_id
            assert len(client.get("/api/v1/claims").json()) == 1
            deleted = client.delete("/api/v1/claims/" + retried.json()["reference"])
            assert deleted.status_code == 200, deleted.text
            assert client.get("/api/v1/claims").json() == []
    finally:
        # Cleanup also handles failures after upload but before the delete assertion.
        for claim in (
            db.collection("claims")
            .where(filter=FieldFilter("client_id", "==", account.uid))
            .stream()
        ):
            for collection in [
                "claim_documents",
                "claim_extracted_fields",
                "claim_processing_jobs",
                "audit_events",
                "notifications",
            ]:
                for row in (
                    db.collection(collection)
                    .where(filter=FieldFilter("claim_id", "==", claim.id))
                    .stream()
                ):
                    path = row.to_dict().get("storage_path")
                    if path:
                        document_store().delete(path)
                    row.reference.delete()
            db.collection("processing_queue").document(claim.id).delete()
            claim.reference.delete()
        db.collection("profiles").document(account.uid).delete()
        auth.delete_user(account.uid, app=fb)
