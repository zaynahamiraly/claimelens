"""Opt-in HTTPS smoke test against the actual running API, with synthetic data."""

import os
import time
import uuid
import pytest

pytestmark = pytest.mark.skipif(
    os.getenv("RUN_PUBLIC_API_TESTS") != "1", reason="Public HTTPS API check is opt-in"
)


def test_public_https_login_image_upload_background_ocr_and_private_download():
    import httpx
    import pymupdf
    from firebase_admin import auth, firestore
    from google.cloud.firestore_v1.base_query import FieldFilter
    from app.firebase import firebase_app
    from app.documents import document_store
    from app.config import get_settings

    endpoint = get_settings().public_api_url
    assert endpoint.startswith("https://"), (
        "Configure the running HTTPS endpoint before enabling this check."
    )
    fb = firebase_app()
    db = firestore.client(fb)
    account = None
    claim_id = None
    try:
        account = auth.create_user(
            email=f"claimelens-internet-test-{uuid.uuid4().hex}@example.com",
            password="Synthetic-public-291!",
            app=fb,
        )
        with httpx.Client(base_url=endpoint, timeout=60) as client:
            health = client.get("/api/v1/health")
            assert health.status_code == 200
            assert client.get("/api/v1/claims").status_code == 401
            signed_in = client.post(
                "/api/v1/auth/login",
                json={"email": account.email, "password": "Synthetic-public-291!"},
            )
            assert signed_in.status_code == 200, signed_in.text
            client.headers["Authorization"] = (
                "Bearer " + signed_in.json()["access_token"]
            )
            with pymupdf.open() as document:
                page = document.new_page(width=600, height=400)
                page.insert_text((40, 70), "MEDICAL INVOICE", fontsize=28)
                page.insert_text((40, 120), "Patient name: Test Person", fontsize=20)
                page.insert_text((40, 170), "Total: MUR 1250.00", fontsize=24)
                image = page.get_pixmap(matrix=pymupdf.Matrix(2, 2)).tobytes("png")
            uploaded = client.post(
                "/api/v1/claims", files={"files": ("synthetic.png", image, "image/png")}
            )
            assert uploaded.status_code == 201, uploaded.text
            claim_id = uploaded.json()["id"]
            url = "/api/v1/claims/" + uploaded.json()["reference"]
            started = client.post(url + "/process", params={"background": "true"})
            assert started.status_code == 200, started.text
            assert started.json()["status"] == "PROCESSING"
            deadline = time.monotonic() + 120
            details = None
            while time.monotonic() < deadline:
                result = client.get(url)
                assert result.status_code == 200, result.text
                details = result.json()
                if details["status"] != "PROCESSING":
                    break
                time.sleep(2)
            assert details["status"] == "UPLOADED", details["status"]
            document = details["documents"][0]
            assert document["extraction_status"] == "COMPLETED", document.get(
                "extraction_notes"
            )
            assert float(document["extracted_amount"]) == 1250
            assert document["signed_url"].startswith(endpoint + "/")
            # A signed link should work without sending the account's bearer token.
            download = httpx.get(document["signed_url"], timeout=30)
            assert download.status_code == 200
            assert download.content == image
            assert (
                httpx.get(document["signed_url"] + "tampered", timeout=30).status_code
                == 403
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
            db.collection("processing_queue").document(claim_id).delete()
            db.collection("claims").document(claim_id).delete()
        if account:
            db.collection("profiles").document(account.uid).delete()
            auth.delete_user(account.uid, app=fb)
