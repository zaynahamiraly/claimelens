"""Disposable live scenarios for one patient with several expenses/claims."""
import io
import os
import uuid
from decimal import Decimal
import pytest

pytestmark = pytest.mark.skipif(os.getenv('RUN_FIREBASE_LIVE_TESTS') != '1', reason='Live Firebase is opt-in')


def test_multiple_expenses_dispute_separate_claims_and_duplicates():
    from docx import Document
    from fastapi.testclient import TestClient
    from firebase_admin import auth, firestore
    from google.cloud.firestore_v1.base_query import FieldFilter
    from app.main import app
    from app.firebase import firebase_app
    from app.documents import document_store

    fb = firebase_app()
    db = firestore.client(fb)
    users, claims = [], []
    password = 'Synthetic-scenarios-2026!'

    def invoice(provider, amount, reference):
        d = Document()
        for line in ['MEDICAL INVOICE', 'Patient name: Scenario Patient',
                     'Provider: ' + provider, 'Invoice: ' + reference, 'Total: MUR ' + str(amount)]:
            d.add_paragraph(line)
        out = io.BytesIO()
        d.save(out)
        return out.getvalue()

    try:
        for role in ['client', 'claims_officer']:
            u = auth.create_user(email=f'claimlens-scenario-{uuid.uuid4().hex}@example.com', password=password, app=fb)
            users.append(u)
        with TestClient(app) as client:
            headers = []
            for u, role in zip(users, ['client', 'claims_officer']):
                r = client.post('/api/v1/auth/login', json={'email': u.email, 'password': password})
                assert r.status_code == 200, r.text
                headers.append({'Authorization': 'Bearer ' + r.json()['access_token']})
                db.collection('profiles').document(u.uid).update({'role': role})
            owner, officer = headers

            def upload(files, key=None):
                r = client.post('/api/v1/claims', headers={**owner, **({'Idempotency-Key': key} if key else {})},
                                files=[('files', (name, body, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')) for name, body in files])
                assert r.status_code == 201, r.text
                if r.json()['id'] not in claims:
                    claims.append(r.json()['id'])
                return '/api/v1/claims/' + r.json()['reference']

            files = [(name + '.docx', invoice(name, amount, name)) for name, amount in [('Hospital', 5000), ('Pharmacy', 800), ('Doctor', 1500)]]
            url = upload(files, 'scenario-' + uuid.uuid4().hex)
            assert client.post(url + '/process', headers=owner).status_code == 200
            detail = client.get(url, headers=owner).json()
            assert sorted(Decimal(str(d['extracted_amount'])) for d in detail['documents']) == [800, 1500, 5000]
            proposed = []
            for d in detail['documents']:
                proposed.append({'id': d['id'], 'include': True,
                                 'amount': '900.00' if d['original_name'] == 'Pharmacy.docx' else str(d['extracted_amount']), 'currency': 'MUR'})
            payload = {'patient_name': 'Scenario Patient', 'provider_name': 'Multiple providers', 'documents': proposed}
            invalid = {**payload, 'documents': [{**d, 'amount': '-1'} for d in proposed]}
            assert client.post(url + '/confirm', headers=owner, json=invalid).status_code == 422
            r = client.post(url + '/confirm', headers=owner, json=payload)
            assert r.status_code == 200, r.text
            assert r.json()['status'] == 'REVIEW_REQUIRED'
            detail = client.get(url, headers=owner).json()
            assert Decimal(str(detail['claimed_amount'])) == 7400
            pharmacy = next(d for d in detail['documents'] if d['original_name'] == 'Pharmacy.docx')
            assert Decimal(str(pharmacy['extracted_amount'])) == 800
            assert Decimal(str(pharmacy['confirmed_amount'])) == 900
            assert pharmacy['client_reported_incorrect_amount'] is True
            assert Decimal(str(pharmacy['client_proposed_amount'])) == 900
            assert client.post(url + '/actions/verify', headers=owner, json={}).status_code == 403
            assert client.post(url + '/actions/claim', headers=officer, json={}).status_code == 200
            corrected = [{**d, 'amount': '800.00'} if d['id'] == pharmacy['id'] else d for d in proposed]
            r = client.post(url + '/actions/correct', headers=officer, json={**payload, 'documents': corrected})
            assert r.status_code == 200, r.text
            assert Decimal(str(client.get(url, headers=owner).json()['claimed_amount'])) == 7300
            checked = client.get(url, headers=officer).json()
            reviewed_pharmacy = next(d for d in checked['documents'] if d['id'] == pharmacy['id'])
            assert Decimal(str(reviewed_pharmacy['client_proposed_amount'])) == 900
            assert Decimal(str(reviewed_pharmacy['confirmed_amount'])) == 800
            assert Decimal(str(reviewed_pharmacy['extracted_amount'])) == 800
            assert client.post(url + '/actions/verify', headers=officer, json={}).status_code == 200

            # A second claim for the same patient is independent of the first.
            second = upload([('Later-visit.docx', invoice('Doctor', 400, 'separate-visit'))])
            assert second != url
            assert client.post(second + '/process', headers=owner).status_code == 200
            d = client.get(second, headers=owner).json()['documents'][0]
            r = client.post(second + '/confirm', headers=owner, json={**payload, 'documents': [{'id': d['id'], 'include': True, 'amount': '400', 'currency': 'MUR'}]})
            assert r.status_code == 200, r.text
            assert Decimal(str(client.get(url, headers=owner).json()['claimed_amount'])) == 7300

            # Retrying an upload must reuse its claim rather than create another.
            key = 'retry-' + uuid.uuid4().hex
            duplicate = upload([files[0]], key)
            assert upload([files[0]], key) == duplicate
            assert client.post(duplicate + '/process', headers=owner).status_code == 200
            d = client.get(duplicate, headers=owner).json()['documents'][0]
            r = client.post(duplicate + '/confirm', headers=owner, json={**payload, 'documents': [{'id': d['id'], 'include': True, 'amount': '5000', 'currency': 'MUR'}]})
            assert r.status_code == 409, r.text
    finally:
        for claim_id in claims:
            for collection in ['claim_documents', 'claim_extracted_fields', 'claim_processing_jobs', 'audit_events', 'notifications', 'claim_information_requests', 'claim_appeals', 'document_fingerprints']:
                for snap in db.collection(collection).where(filter=FieldFilter('claim_id', '==', claim_id)).stream():
                    path = snap.to_dict().get('storage_path')
                    if path:
                        document_store().delete(path)
                    snap.reference.delete()
            db.collection('processing_queue').document(claim_id).delete()
            db.collection('claims').document(claim_id).delete()
        for u in users:
            db.collection('profiles').document(u.uid).delete()
            auth.delete_user(u.uid, app=fb)
