from types import SimpleNamespace
from unittest.mock import Mock
import time
from app import jobs


def store_for(monkeypatch, *, lease=0, attempts=1, status='PROCESSING'):
    monkeypatch.setattr(jobs.firestore, 'transactional', lambda fn: fn)
    queue = {'claim_id': 'claim', 'actor_id': 'owner', 'state': 'RUNNING', 'lease_until': lease, 'attempts': attempts}
    claim = {'id': 'claim', 'status': status}
    def reference(data):
        ref = SimpleNamespace(data=data)
        ref.get = lambda **kwargs: SimpleNamespace(to_dict=lambda: dict(data))
        return ref
    queue_ref, claim_ref = reference(queue), reference(claim)
    snapshot = SimpleNamespace(reference=queue_ref, to_dict=lambda: dict(queue))
    query = Mock(); query.where.return_value = query; query.limit.return_value = query; query.stream.return_value = [snapshot]
    claims = SimpleNamespace(document=lambda uid: claim_ref)
    transaction = SimpleNamespace(update=lambda ref, update: ref.data.update(update))
    db = SimpleNamespace(collection=lambda name: query if name == 'processing_queue' else claims, transaction=lambda: transaction)
    return SimpleNamespace(db=db), queue, claim


def test_expired_job_is_recovered_with_a_new_lease(monkeypatch):
    store, queue, claim = store_for(monkeypatch, lease=time.time()-10)
    result = jobs.take_job(store, 'replacement-worker')
    assert result['claim']['id'] == 'claim'
    assert queue['worker'] == 'replacement-worker'
    assert queue['attempts'] == 2
    assert queue['lease_until'] > time.time()


def test_active_worker_lease_is_not_taken_over(monkeypatch):
    store, queue, claim = store_for(monkeypatch, lease=time.time()+60)
    assert jobs.take_job(store, 'other-worker') is None
    assert queue['attempts'] == 1


def test_a_stale_job_cannot_return_a_submitted_claim_to_draft(monkeypatch):
    store, queue, claim = store_for(monkeypatch, status='REVIEW_REQUIRED')
    assert jobs.take_job(store, 'other-worker') is None
    assert queue['state'] == 'CANCELLED'
    assert claim['status'] == 'REVIEW_REQUIRED'


def test_restart_retries_are_bounded(monkeypatch):
    store, queue, claim = store_for(monkeypatch, attempts=3)
    assert jobs.take_job(store, 'other-worker') is None
    assert queue['state'] == 'FAILED'
    assert claim['status'] == 'PROCESSING_FAILED'
