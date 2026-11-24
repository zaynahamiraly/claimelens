"""Durable Firestore OCR queue with leases and bounded recovery after a restart."""

import asyncio
import logging
import secrets
import time
from types import SimpleNamespace
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from .firebase import FirebaseGateway, now

log = logging.getLogger(__name__)


def queue_record(claim, actor):
    return {
        "claim_id": claim["id"],
        "actor_id": actor,
        "state": "QUEUED",
        "attempts": 0,
        "lease_until": 0,
        "created_at": now(),
    }


async def enqueue(gateway, claim, actor):
    await asyncio.to_thread(
        gateway.db.collection("processing_queue").document(claim["id"]).set,
        queue_record(claim, actor),
    )


def take_job(store, worker):
    candidates = list(
        store.db.collection("processing_queue")
        .where(filter=FieldFilter("state", "in", ["QUEUED", "RUNNING"]))
        .limit(100)
        .stream()
    )
    candidates.sort(key=lambda s: s.to_dict().get("created_at", ""))
    for candidate in candidates:

        @firestore.transactional
        def acquire(transaction):
            record = candidate.reference.get(transaction=transaction).to_dict() or {}
            if (
                record.get("state") not in {"QUEUED", "RUNNING"}
                or record.get("lease_until", 0) > time.time()
            ):
                return None
            ref = store.db.collection("claims").document(record["claim_id"])
            claim = ref.get(transaction=transaction).to_dict()
            if not claim:
                transaction.update(candidate.reference, {"state": "CANCELLED"})
                return None
            if claim.get("status") != "PROCESSING":
                transaction.update(
                    candidate.reference, {"state": "CANCELLED", "finished_at": now()}
                )
                return None
            if record.get("attempts", 0) >= 3:
                transaction.update(
                    candidate.reference, {"state": "FAILED", "finished_at": now()}
                )
                transaction.update(ref, {"status": "PROCESSING_FAILED"})
                return None
            transaction.update(
                candidate.reference,
                {
                    "state": "RUNNING",
                    "worker": worker,
                    "lease_until": time.time() + 90,
                    "attempts": record.get("attempts", 0) + 1,
                },
            )
            transaction.update(ref, {"status": "PROCESSING"})
            return {**record, "claim": claim, "reference": candidate.reference}

        job = acquire(store.db.transaction())
        if job:
            return job
    return None


async def heartbeat(job):
    while True:
        await asyncio.sleep(20)
        await asyncio.to_thread(
            job["reference"].update, {"lease_until": time.time() + 90}
        )


async def worker_loop():
    worker = secrets.token_hex(12)
    while True:
        try:
            store = FirebaseGateway(SimpleNamespace(state=SimpleNamespace()))
            job = await asyncio.to_thread(take_job, store, worker)
            if not job:
                await asyncio.sleep(5)
                continue
            pulse = asyncio.create_task(heartbeat(job))
            try:
                from .routers.claims import finish_processing

                await finish_processing(store, job["claim"], job["actor_id"])
                await asyncio.to_thread(
                    job["reference"].update,
                    {"state": "COMPLETED", "lease_until": 0, "finished_at": now()},
                )
            except asyncio.CancelledError:
                raise
            except Exception:
                log.exception(
                    "OCR job failed for a claim; details are available to authorized reviewers."
                )
                await asyncio.to_thread(
                    job["reference"].update,
                    {"state": "FAILED", "lease_until": 0, "finished_at": now()},
                )
            finally:
                pulse.cancel()
                await asyncio.gather(pulse, return_exceptions=True)
        except asyncio.CancelledError:
            raise
        except Exception:
            log.exception("Processing worker unavailable; retrying.")
            await asyncio.sleep(15)
