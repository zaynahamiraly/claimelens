from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv


load_dotenv(Path(__file__).resolve().parents[1] / ".env", encoding="utf-8-sig")


@dataclass(frozen=True)
class Settings:
    firebase_project_id: str = os.getenv("FIREBASE_PROJECT_ID", "claimelens")
    firebase_api_key: str = os.getenv("FIREBASE_API_KEY", "")
    firebase_credentials: str = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")
    document_storage_path: str = os.getenv(
        "DOCUMENT_STORAGE_PATH",
        str(
            Path(os.getenv("LOCALAPPDATA", str(Path.home() / ".local/share")))
            / "claimelens/documents"
        ),
    )
    public_api_url: str = (
        os.getenv("PUBLIC_API_URL")
        or os.getenv("RENDER_EXTERNAL_URL")
        or "http://127.0.0.1:8000"
    )
    max_file_bytes: int = int(os.getenv("MAX_UPLOAD_BYTES", str(10 * 1024 * 1024)))
    max_claim_documents: int = int(os.getenv("MAX_CLAIM_DOCUMENTS", "10"))
    paddle_device: str = os.getenv("PADDLE_DEVICE", "cpu")
    cors_origins_raw: str = os.getenv("CORS_ORIGINS", "http://localhost:3000")

    @property
    def cors_origins(self) -> list[str]:
        return [
            value.strip() for value in self.cors_origins_raw.split(",") if value.strip()
        ]


@lru_cache
def get_settings() -> Settings:
    return Settings()


def maintenance_mode() -> bool:
    return os.getenv("CLAIMLENS_MAINTENANCE", "false").lower() == "true"
