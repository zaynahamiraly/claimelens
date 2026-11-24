"""Opt-in worker/Firestore/private-storage check with a generated image only."""
import os
import time
import uuid
import pytest

pytestmark = pytest.mark.skipif(os.getenv('RUN_FIREBASE_LIVE_TESTS') != '1' or os.getenv('RUN_PADDLE_OCR_TESTS') != '1', reason='Real worker check requires both live-test opt-ins')


def test_durable_worker_processes_a_queued_image(monkeypatch):
    from fastapi.testclient import TestClient
    from firebase_admin import auth, firestore
    from google.cloud.firestore_v1.base_query import FieldFilter
    import pymupdf
    from app.main import app
    from app.firebase import firebase_app
    from app.documents import document_store
    fb = firebase_app(); db = firestore.client(fb)
    account = auth.create_user(email=f'claimlens-worker-test-{uuid.uuid4().hex}@example.com', password='Synthetic-worker-291!', app=fb)
    identifier = None
    monkeypatch.setenv('PROCESSING_WORKER_ENABLED', 'true')
    try:
        with TestClient(app) as client:
            login = client.post('/api/v1/auth/login', json={'email': account.email, 'password': 'Synthetic-worker-291!'})
            assert login.status_code == 200, login.text
            headers = {'Authorization': 'Bearer ' + login.json()['access_token']}
            with pymupdf.open() as document:
                page = document.new_page(width=600, height=400)
                page.insert_text((40, 70), 'MEDICAL INVOICE', fontsize=28)
                page.insert_text((40, 120), 'Patient name: Synthetic Person', fontsize=20)
                page.insert_text((40, 170), 'Total: MUR 1250.00', fontsize=24)
                image = page.get_pixmap(matrix=pymupdf.Matrix(2, 2)).tobytes('png')
            result = client.post('/api/v1/claims', headers=headers, files={'files': ('synthetic.png', image, 'image/png')})
            assert result.status_code == 201, result.text
            identifier = result.json()['id']; reference = result.json()['reference']
            result = client.post(f'/api/v1/claims/{reference}/process?background=true', headers=headers)
            assert result.status_code == 200, result.text
            assert result.json()['status'] == 'PROCESSING'
            deadline = time.monotonic()+150
            while time.monotonic() < deadline:
                queue = db.collection('processing_queue').document(identifier).get().to_dict()
                if queue.get('state') in {'COMPLETED', 'FAILED'}:
                    break
                time.sleep(2)
            assert queue['state'] == 'COMPLETED', queue.get('state')
            detail = client.get(f'/api/v1/claims/{reference}', headers=headers)
            assert detail.status_code == 200, detail.text
            assert detail.json()['status'] == 'UPLOADED'
            assert float(detail.json()['documents'][0]['extracted_amount']) == 1250
    finally:
        if identifier:
            for collection in ['claim_documents', 'claim_extracted_fields', 'claim_processing_jobs', 'audit_events', 'notifications']:
                for snapshot in db.collection(collection).where(filter=FieldFilter('claim_id', '==', identifier)).stream():
                    path = snapshot.to_dict().get('storage_path')
                    if path:
                        document_store().delete(path)
                    snapshot.reference.delete()
            db.collection('processing_queue').document(identifier).delete()
            db.collection('claims').document(identifier).delete()
        db.collection('profiles').document(account.uid).delete()
        auth.delete_user(account.uid, app=fb)
