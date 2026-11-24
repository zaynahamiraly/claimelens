"""Private local document storage for the no-billing development setup."""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
from pathlib import Path
import secrets
from threading import Lock
import time
from urllib.parse import urlencode, quote

from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from cryptography.fernet import Fernet, InvalidToken

from .config import get_settings

_key_lock = Lock()
router = APIRouter(prefix="/documents", tags=["documents"])


class LocalDocuments:
    def __init__(self, root: str | Path, public_api_url: str):
        self.root = Path(root).resolve()
        self.public_api_url = public_api_url.rstrip("/")

    def file(self, path: str) -> Path:
        # Storage paths are constructed by the API as uid/claim-id/random-name.
        parts = path.split("/")
        if len(parts) != 3 or any(
            p in {"", ".", ".."} or "\\" in p or ":" in p for p in parts
        ):
            raise HTTPException(403, "Invalid document link.")
        base = (self.root / "files").resolve()
        target = base.joinpath(*parts).resolve()
        if not target.is_relative_to(base):
            raise HTTPException(403, "Invalid document link.")
        return target

    def _metadata(self, path: str) -> Path:
        return (
            self.root
            / "metadata"
            / (hashlib.sha256(path.encode()).hexdigest() + ".json")
        )

    def _cipher(self):
        key = os.getenv("DOCUMENT_ENCRYPTION_KEY")
        if key:
            return Fernet(key.encode())
        with _key_lock:
            self.root.mkdir(parents=True, exist_ok=True)
            path = self.root / ".encryption-key"
            try:
                descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            except FileExistsError:
                pass
            else:
                with os.fdopen(descriptor, "wb") as stream:
                    stream.write(Fernet.generate_key())
            return Fernet(path.read_bytes())

    def _key(self) -> bytes:
        with _key_lock:
            self.root.mkdir(parents=True, exist_ok=True)
            key_path = self.root / ".signing-key"
            if not key_path.exists():
                descriptor = os.open(
                    key_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600
                )
                with os.fdopen(descriptor, "wb") as stream:
                    stream.write(secrets.token_bytes(32))
            return key_path.read_bytes()

    def upload(self, path: str, content: bytes, content_type: str):
        target = self.file(path)
        target.parent.mkdir(parents=True, exist_ok=True)
        encrypted = self._cipher().encrypt(content)
        with target.open("xb") as stream:
            stream.write(encrypted)
        metadata = self._metadata(path)
        metadata.parent.mkdir(parents=True, exist_ok=True)
        try:
            metadata.write_text(
                json.dumps({"content_type": content_type, "encrypted": True}),
                encoding="utf-8",
            )
        except Exception:
            target.unlink(missing_ok=True)
            raise

    def download(self, path: str) -> bytes:
        target = self.file(path)
        if not target.is_file():
            raise HTTPException(404, "Document not found on this API server.")
        content = target.read_bytes()
        metadata = json.loads(self._metadata(path).read_text(encoding="utf-8"))
        if metadata.get("encrypted"):
            try:
                return self._cipher().decrypt(content)
            except InvalidToken:
                raise HTTPException(
                    503,
                    "The document cannot be decrypted. Contact your administrator to check the storage key.",
                )
        return content

    def delete(self, path: str):
        self.file(path).unlink(missing_ok=True)
        self._metadata(path).unlink(missing_ok=True)

    def _signature(self, path: str, expires: int) -> str:
        return hmac.new(
            self._key(), f"{path}\n{expires}".encode(), hashlib.sha256
        ).hexdigest()

    def signed_url(self, path: str, expires_in: int = 300) -> str:
        self.file(path)
        expires = int(time.time()) + min(300, max(1, expires_in))
        encoded = base64.urlsafe_b64encode(path.encode()).decode()
        return (
            self.public_api_url
            + "/api/v1/documents/download?"
            + urlencode(
                {
                    "document": encoded,
                    "expires": expires,
                    "signature": self._signature(path, expires),
                }
            )
        )

    def verify(self, document: str, expires: int, signature: str) -> tuple[Path, str]:
        try:
            path = base64.b64decode(
                document.encode(), altchars=b"-_", validate=True
            ).decode()
        except (ValueError, UnicodeError):
            raise HTTPException(403, "Invalid document link.")
        if expires < time.time() or not hmac.compare_digest(
            self._signature(path, expires), signature
        ):
            raise HTTPException(
                403, "Document link has expired or is invalid. Open the claim again."
            )
        target = self.file(path)
        if not target.is_file():
            raise HTTPException(404, "Document not found on this API server.")
        metadata = json.loads(self._metadata(path).read_text(encoding="utf-8"))
        return target, metadata["content_type"]


def document_store():
    settings = get_settings()
    return LocalDocuments(settings.document_storage_path, settings.public_api_url)


@router.get("/download")
def download_document(document: str, expires: int, signature: str):
    store = document_store()
    target, content_type = store.verify(document, expires, signature)
    path = target.relative_to(store.root / "files").as_posix()
    return Response(
        store.download(path),
        media_type=content_type,
        headers={
            "Cache-Control": "private, no-store",
            "X-Content-Type-Options": "nosniff",
            "Content-Disposition": "attachment; filename*=UTF-8''" + quote(target.name),
        },
    )
