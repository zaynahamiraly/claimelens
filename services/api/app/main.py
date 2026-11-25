from contextlib import asynccontextmanager
import asyncio
import os

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from .config import get_settings, maintenance_mode
from .routers import auth, claims, profile, workspace
from .documents import router as documents_router
from .routers.claim_tools import router as claim_tools_router
from .push import router as push_router
from .routers.chat import router as chat_router


APP_NAME = "ClaimLens API"
APP_VERSION = "1.2.0"


@asynccontextmanager
async def lifespan(application: FastAPI):
    application.state.http = httpx.AsyncClient(timeout=httpx.Timeout(60.0))
    from .jobs import worker_loop

    worker = (
        asyncio.create_task(worker_loop())
        if not maintenance_mode() and os.getenv("PROCESSING_WORKER_ENABLED", "true").lower() == "true"
        else None
    )
    from .push import push_loop

    push_worker = (
        asyncio.create_task(push_loop())
        if not maintenance_mode() and os.getenv("PUSH_WORKER_ENABLED", "true").lower() == "true"
        else None
    )
    yield
    if worker:
        worker.cancel()
        await asyncio.gather(worker, return_exceptions=True)
    if push_worker:
        push_worker.cancel()
        await asyncio.gather(push_worker, return_exceptions=True)
    await application.state.http.aclose()


app = FastAPI(
    title=APP_NAME,
    description="Firebase API for ClaimLens",
    version=APP_VERSION,
    lifespan=lifespan,
)

settings = get_settings()

@app.exception_handler(RequestValidationError)
async def validation_error(request, error):
    # Do not echo passwords, tokens or medical input in validation errors.
    return JSONResponse({'detail': [{'loc': list(item['loc']), 'msg': item['msg'], 'type': item['type']} for item in error.errors()]}, status_code=422)
from .hardening import security_defaults

app.middleware("http")(security_defaults)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1")
app.include_router(profile.router, prefix="/api/v1")
app.include_router(claims.router, prefix="/api/v1")
app.include_router(documents_router, prefix="/api/v1")
app.include_router(workspace.router, prefix="/api/v1")
app.include_router(claim_tools_router, prefix="/api/v1")
app.include_router(push_router, prefix="/api/v1")
app.include_router(chat_router, prefix="/api/v1")


@app.get("/", tags=["service"])
def root() -> dict[str, str]:
    return {
        "name": APP_NAME,
        "version": APP_VERSION,
        "status": "running",
    }


@app.get("/api/v1/health", tags=["service"])
def health_check() -> dict[str, str]:
    return {
        "status": "healthy",
        "service": APP_NAME,
        "version": APP_VERSION,
    }
