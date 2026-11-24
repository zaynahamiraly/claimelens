"""Request limits and safe response defaults for the single-instance pilot API."""

import asyncio
import hashlib
from pathlib import Path
import sqlite3
import time
import uuid
from fastapi import Request
from fastapi.responses import JSONResponse
from .config import get_settings


def consume(key, limit, seconds):
    path = Path(get_settings().document_storage_path) / "request-limits.sqlite3"
    path.parent.mkdir(parents=True, exist_ok=True)
    now = time.time()
    with sqlite3.connect(path, timeout=10) as connection:
        connection.execute(
            "CREATE TABLE IF NOT EXISTS limits (key TEXT PRIMARY KEY, count INTEGER, reset REAL)"
        )
        connection.execute("BEGIN IMMEDIATE")
        row = connection.execute(
            "SELECT count, reset FROM limits WHERE key=?", (key,)
        ).fetchone()
        count, reset = row if row and row[1] > now else (0, now + seconds)
        if count >= limit:
            return max(1, int(reset - now))
        connection.execute(
            "INSERT OR REPLACE INTO limits VALUES (?, ?, ?)", (key, count + 1, reset)
        )
        connection.execute("DELETE FROM limits WHERE reset < ?", (now - 3600,))
    return 0


async def security_defaults(request: Request, call_next):
    route = request.url.path
    request_id = uuid.uuid4().hex
    if request.method == "POST" and (
        route
        in {
            "/api/v1/auth/login",
            "/api/v1/auth/signup",
            "/api/v1/auth/forgot-password",
            "/api/v1/auth/mfa/verify",
            "/api/v1/profile/unlock",
            "/api/v1/auth/verification-email",
            "/api/v1/profile/password",
        }
        or route.endswith("/password")
    ):
        # Forwarded client headers are deliberately not trusted. Production reverse
        # proxy configuration must supply a trusted client address to the ASGI server.
        address = request.client.host if request.client else "unknown"
        key = hashlib.sha256((address + ":" + route).encode()).hexdigest()
        wait = await asyncio.to_thread(
            consume, key, 30 if route.endswith("/login") else 10, 60
        )
        if wait:
            return JSONResponse(
                {"detail": "Too many attempts. Please wait and try again."},
                status_code=429,
                headers={"Retry-After": str(wait), "Cache-Control": "no-store"},
            )
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Cache-Control"] = "no-store"
    return response
