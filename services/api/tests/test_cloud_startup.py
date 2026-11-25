"""Cloud startup must respect routing and protect the live database during migration."""

import os
import subprocess
import sys

from fastapi.testclient import TestClient

from app import serve
from app.main import app


def test_provider_port_and_explicit_override(monkeypatch):
    calls = []
    monkeypatch.setattr(serve, "_engine", lambda: None)
    monkeypatch.setattr(serve.uvicorn, "run", lambda *args, **kwargs: calls.append(kwargs))
    monkeypatch.setenv("PORT", "10000")
    monkeypatch.setattr(sys, "argv", ["serve", "--host", "0.0.0.0"])
    serve.main()
    monkeypatch.setattr(sys, "argv", ["serve", "--port", "9000"])
    serve.main()
    assert calls == [dict(host="0.0.0.0", port=10000), dict(host="127.0.0.1", port=9000)]


def test_render_url_and_explicit_override():
    env = dict(os.environ, PUBLIC_API_URL="", RENDER_EXTERNAL_URL="https://example.onrender.com")
    command = [sys.executable, "-c", "from app.config import Settings; print(Settings().public_api_url)"]
    assert subprocess.check_output(command, env=env, text=True).strip() == "https://example.onrender.com"
    env["PUBLIC_API_URL"] = "https://api.example.org"
    assert subprocess.check_output(command, env=env, text=True).strip() == "https://api.example.org"


def test_maintenance_blocks_api_and_workers_but_allows_health(monkeypatch):
    from app import jobs, push

    monkeypatch.setenv("CLAIMLENS_MAINTENANCE", "true")
    monkeypatch.setenv("PROCESSING_WORKER_ENABLED", "true")
    monkeypatch.setenv("PUSH_WORKER_ENABLED", "true")
    # Fail synchronously if either worker coroutine is even constructed.
    monkeypatch.setattr(jobs, "worker_loop", lambda: (_ for _ in ()).throw(AssertionError("worker started")))
    monkeypatch.setattr(push, "push_loop", lambda: (_ for _ in ()).throw(AssertionError("push started")))
    with TestClient(app) as client:
        assert client.get("/api/v1/health").status_code == 200
        for method, route in [("post", "/api/v1/auth/login"), ("get", "/api/v1/claims"), ("get", "/api/v1/documents/example")]:
            response = getattr(client, method)(route)
            assert response.status_code == 503
            assert response.headers["Retry-After"] == "60"
            assert response.headers["Cache-Control"] == "no-store"
