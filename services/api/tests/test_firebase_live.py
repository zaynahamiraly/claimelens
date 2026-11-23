"""Opt-in live check with disposable accounts and a generated Word invoice.

RUN_FIREBASE_LIVE_TESTS=1 enables writes to the configured Firebase project.
Only records created by this test are removed afterward. No emails are sent.
"""
import io
import os
import uuid
import pytest

pytestmark = pytest.mark.skipif(os.getenv('RUN_FIREBASE_LIVE_TESTS') != '1', reason='Live Firebase check is opt-in')


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
        for _ in range(2):
            users.append(auth.create_user(email=f'claimelens-test-{uuid.uuid4().hex}@example.com', password='Synthetic-check-291!', app=fb))
        with TestClient(app) as client:
            headers = []
            refresh_token = None
            for user in users:
                response = client.post('/api/v1/auth/login', json={'email': user.email, 'password': 'Synthetic-check-291!'})
                assert response.status_code == 200, response.text
                assert response.json()['user']['role'] == 'client'
                headers.append({'Authorization': 'Bearer ' + response.json()['access_token']})
                refresh_token = response.json()['refresh_token']
            assert client.post('/api/v1/auth/refresh', json={'refresh_token': refresh_token}).status_code == 200
            assert client.get('/api/v1/profile', headers=headers[0]).status_code == 200
            invoice = Document()
            for line in ['TEST MEDICAL CLINIC', 'INVOICE', 'Patient name: Synthetic Person', 'Total: MUR 1250.00']:
                invoice.add_paragraph(line)
            output = io.BytesIO()
            invoice.save(output)
            response = client.post('/api/v1/claims', headers=headers[0], files={'files': ('invoice.docx', output.getvalue(), 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')})
            assert response.status_code == 201, response.text
            data = response.json()
            claim_id = data['id']
            url = '/api/v1/claims/' + data['reference']
            assert client.get(url, headers=headers[1]).status_code == 404
            assert client.post(url + '/process', headers=headers[1]).status_code == 404
            response = client.post(url + '/process', headers=headers[0])
            assert response.status_code == 200, response.text
            assert response.json()['extracted_field_count'] > 0
            details = client.get(url, headers=headers[0])
            assert details.status_code == 200, details.text
            document = details.json()['documents'][0]
            assert float(document['extracted_amount']) == 1250
            link = document['signed_url'].replace('http://127.0.0.1:8000', '')
            downloaded = client.get(link)
            assert downloaded.status_code == 200
            assert downloaded.content == output.getvalue()
            assert client.get(link + 'tampered').status_code == 403
            payload = {'patient_name': 'Synthetic Person', 'provider_name': 'Test Medical Clinic', 'documents': [{'id': document['id'], 'include': True, 'amount': '1250.00', 'currency': 'MUR'}]}
            assert client.post(url + '/confirm', headers=headers[1], json=payload).status_code == 404
            result = client.post(url + '/confirm', headers=headers[0], json=payload)
            assert result.status_code == 200, result.text
            assert result.json()['status'] == 'REVIEW_REQUIRED'
            assert client.post(url + '/confirm', headers=headers[0], json=payload).status_code in (403, 409)
            assert db.collection('claims').document(claim_id).get().to_dict()['claimed_amount'] == '1250.00'
    finally:
        if claim_id:
            for collection in ['claim_documents', 'claim_extracted_fields', 'claim_processing_jobs', 'audit_events']:
                for document in db.collection(collection).where(filter=FieldFilter('claim_id', '==', claim_id)).stream():
                    path = document.to_dict().get('storage_path')
                    if path:
                        document_store().delete(path)
                    document.reference.delete()
            db.collection('claims').document(claim_id).delete()
        for user in users:
            db.collection('profiles').document(user.uid).delete()
            auth.delete_user(user.uid, app=fb)
