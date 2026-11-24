import os

# Unit tests must never start an external database worker implicitly.
os.environ["PROCESSING_WORKER_ENABLED"] = "false"
os.environ["PUSH_WORKER_ENABLED"] = "false"

import pytest


@pytest.fixture(autouse=True)
def isolated_request_limits(monkeypatch):
    # Unit tests exercise the limiter explicitly, without sharing live counters.
    from app import hardening

    monkeypatch.setattr(hardening, "consume", lambda *args: 0)
