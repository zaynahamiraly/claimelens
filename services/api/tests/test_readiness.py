from types import SimpleNamespace
import io
import zipfile
import pytest
from cryptography.exceptions import InvalidTag
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.main import app
from app.security import get_current_user
from app.workflow import available_actions, workflow_patch, WorkflowInput
from app.permissions import permissions
from app.firebase import can_access_claim
from app.routers import workspace
from app import hardening
from app.backups import create_backup, open_backup
from app.documents import LocalDocuments

rate_limit = hardening.consume


def user(role, uid='test', rights=()):
    return SimpleNamespace(id=uid, email='synthetic@example.com', profile=SimpleNamespace(role=role, permissions=list(rights)))


def test_account_administration_does_not_imply_approval_or_payment():
    admin = user('administrator')
    assert 'users.manage' in permissions(admin.profile)
    assert available_actions(admin, {'status': 'VERIFIED', 'verified_by': 'other'}) == []
    assert available_actions(admin, {'status': 'PAYMENT_PENDING'}) == []
    elevated = user('administrator', rights=['claims.decide'])
    assert available_actions(elevated, {'status': 'VERIFIED', 'verified_by': 'other'}) == ['approve', 'reject']


def test_reviewer_cannot_approve_their_own_verification():
    supervisor = user('supervisor')
    assert available_actions(supervisor, {'status': 'VERIFIED', 'verified_by': supervisor.id}) == []
    with pytest.raises(HTTPException) as error:
        workflow_patch(supervisor, {'status': 'VERIFIED', 'verified_by': supervisor.id}, 'approve', WorkflowInput(notes='Checked evidence', approved_amount='100'))
    assert error.value.status_code == 403


def test_finance_only_sees_claims_ready_for_settlement_and_requires_reference():
    finance = user('finance')
    assert not can_access_claim(finance, {'status': 'UPLOADED'})
    assert not can_access_claim(finance, {'status': 'REVIEW_REQUIRED'})
    assert can_access_claim(finance, {'status': 'APPROVED'})
    with pytest.raises(HTTPException) as error:
        workflow_patch(finance, {'status': 'PAYMENT_PENDING'}, 'paid', WorkflowInput())
    assert error.value.status_code == 422
    patch, _ = workflow_patch(finance, {'status': 'PAYMENT_PENDING'}, 'paid', WorkflowInput(payment_reference='SYNTHETIC-001', payment_method='bank_transfer'))
    assert patch['payment_reference'] == 'SYNTHETIC-001'


@pytest.mark.parametrize('role', ['client', 'claims_officer', 'supervisor', 'finance'])
def test_only_admin_can_set_someone_elses_password(role):
    app.dependency_overrides[get_current_user] = lambda: user(role)
    try:
        with TestClient(app) as client:
            result = client.post('/api/v1/users/another/password', json={'admin_password': 'Synthetic-only-password', 'new_password': 'Synthetic-temporary-291!'})
        assert result.status_code == 403
    finally:
        app.dependency_overrides.clear()


def test_admin_cannot_bypass_current_password_for_own_password_change():
    app.dependency_overrides[get_current_user] = lambda: user('administrator')
    try:
        with TestClient(app) as client:
            result = client.post('/api/v1/users/test/password', json={'admin_password': 'Synthetic-only-password', 'new_password': 'Synthetic-temporary-291!'})
        assert result.status_code == 422
    finally:
        app.dependency_overrides.clear()


def test_password_validation_never_echoes_the_password():
    app.dependency_overrides[get_current_user] = lambda: user('administrator')
    try:
        with TestClient(app) as client:
            result = client.post('/api/v1/users/another/password', json={'admin_password': 'private-admin-password', 'new_password': 'abc'})
        assert result.status_code == 422
        assert 'private-admin-password' not in result.text
        assert '"input"' not in result.text
        assert 'abc' not in result.text
    finally:
        app.dependency_overrides.clear()


def test_unknown_permission_cannot_be_granted():
    with pytest.raises(ValueError):
        workspace.UserEdit(display_name='Test User', role='client', status='active', permissions=['users.manage'])


def test_rate_limit_persists_between_calls_and_returns_retry_delay(tmp_path, monkeypatch):
    monkeypatch.setattr(hardening, 'get_settings', lambda: SimpleNamespace(document_storage_path=str(tmp_path)))
    assert rate_limit('synthetic-ip', 2, 60) == 0
    assert rate_limit('synthetic-ip', 2, 60) == 0
    assert rate_limit('synthetic-ip', 2, 60) > 0
    assert rate_limit('different-ip', 2, 60) == 0


def test_encrypted_backup_roundtrip_and_tamper_rejection(tmp_path):
    storage = tmp_path/'storage'
    store = LocalDocuments(storage, 'http://127.0.0.1:8000')
    store.upload('test/claim/invoice.pdf', b'%PDF-private synthetic evidence', 'application/pdf')
    records = {'profiles': {'test': {'display_name': 'Synthetic Person'}}}
    output = tmp_path/'backup.clb'
    create_backup(storage, records, 'test-project', output, 'Synthetic backup passphrase 291!')
    assert b'Synthetic Person' not in output.read_bytes()
    assert b'private synthetic evidence' not in output.read_bytes()
    temporary, archive, manifest = open_backup(output, 'Synthetic backup passphrase 291!')
    try:
        assert manifest['collections'] == records
        assert 'storage/.encryption-key' in archive.namelist()
    finally:
        archive.close(); temporary.close()
    corrupted = tmp_path/'corrupted.clb'
    content = bytearray(output.read_bytes()); content[50] ^= 1; corrupted.write_bytes(content)
    with pytest.raises(InvalidTag):
        open_backup(corrupted, 'Synthetic backup passphrase 291!')
    with pytest.raises(InvalidTag):
        open_backup(output, 'Different backup passphrase 292!')


def test_legacy_documents_remain_readable(tmp_path):
    import json
    store = LocalDocuments(tmp_path, 'http://localhost')
    target = store.file('test/claim/legacy.pdf'); target.parent.mkdir(parents=True)
    target.write_bytes(b'%PDF-old-document')
    metadata = store._metadata('test/claim/legacy.pdf'); metadata.parent.mkdir(parents=True)
    metadata.write_text(json.dumps({'content_type': 'application/pdf'}))
    assert store.download('test/claim/legacy.pdf') == b'%PDF-old-document'


def test_oversized_docx_expansion_is_rejected():
    from app.routers.claims import valid_signature
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr('word/document.xml', b'x'*(51*1024*1024))
    assert not valid_signature(buffer.getvalue(), 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
