from types import SimpleNamespace
from unittest.mock import AsyncMock
import httpx
import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from app.main import app
from app.routers import auth
from app.firebase import can_access_claim


def test_claim_access_is_scoped_by_role():
    claim={'client_id':'owner','assigned_to':'officer'}
    for uid,role,expected in [('owner','client',True),('other','client',False),('officer','claims_officer',True),('other','claims_officer',False),('boss','supervisor',True),('admin','administrator',True)]:
        user=SimpleNamespace(id=uid,profile=SimpleNamespace(role=role))
        assert can_access_claim(user,claim) == expected


def test_signup_does_not_accept_client_supplied_role(monkeypatch):
    upstream=AsyncMock(return_value={'localId':'new-client','idToken':'test-token'})
    profile=AsyncMock()
    monkeypatch.setattr(auth,'firebase_request',upstream)
    monkeypatch.setattr(auth,'FirebaseGateway',lambda request: SimpleNamespace(ensure_profile=profile))
    with TestClient(app) as client:
        result=client.post('/api/v1/auth/signup',json={'email':'Client@example.com','display_name':'Client','password':'long-password','role':'administrator'})
    assert result.status_code == 200
    assert profile.call_args.args == ('new-client','Client','client@example.com')
    assert upstream.call_args_list[0].args[2]['email'] == 'client@example.com'
    assert 'role' not in upstream.call_args_list[0].args[2]
    assert 'idToken' not in result.json()


def test_recovery_uses_firebase_hosted_link(monkeypatch):
    upstream=AsyncMock(return_value={})
    monkeypatch.setattr(auth,'firebase_request',upstream)
    with TestClient(app) as client:
        result=client.post('/api/v1/auth/forgot-password',json={'email':'client@example.com'})
    assert result.status_code == 200
    assert upstream.call_args.args[2]['requestType'] == 'PASSWORD_RESET'
    assert 'link' in result.json()['message']


def test_password_validation_precedes_network(monkeypatch):
    upstream=AsyncMock()
    monkeypatch.setattr(auth,'firebase_request',upstream)
    with TestClient(app) as client:
        result=client.post('/api/v1/auth/signup',json={'email':'client@example.com','display_name':'Client','password':'short'})
    assert result.status_code == 422
    upstream.assert_not_called()


def test_invalid_firebase_token_is_rejected(monkeypatch):
    from app import security
    monkeypatch.setattr(security,'firebase_app',lambda:None)
    monkeypatch.setattr(security.auth,'verify_id_token',lambda *a,**kw: (_ for _ in ()).throw(ValueError('bad token')))
    with TestClient(app) as client:
        response=client.get('/api/v1/profile',headers={'Authorization':'Bearer invalid'})
    assert response.status_code == 401
