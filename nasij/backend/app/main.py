import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import auth, batches, alerts, sync, suppliers, dashboard, users, ai


async def _supabase_keepalive(settings):
    """Ping Supabase every 5 minutes to prevent cold-start latency on free tier."""
    from supabase import create_client
    while True:
        await asyncio.sleep(300)  # 5 minutes
        try:
            client = create_client(settings.supabase_url, settings.supabase_service_role_key)
            await asyncio.to_thread(
                lambda: client.table("users").select("id").limit(1).execute()
            )
        except Exception:
            pass  # Keepalive failure is non-fatal


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    print(f"[NASIJ] Mobile backend started — Supabase: {settings.supabase_url}")
    print(f"[NASIJ] Port: {settings.port} | CORS: {settings.cors_origins}")
    task = asyncio.create_task(_supabase_keepalive(settings))
    yield
    task.cancel()
    print("[NASIJ] Mobile backend shutting down")


app = FastAPI(
    title="NASIJ Mobile API",
    description="FastAPI backend for the NASIJ mobile app — wool traceability platform",
    version="1.0.0",
    lifespan=lifespan,
)

settings = get_settings()
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api")
app.include_router(batches.router, prefix="/api")
app.include_router(alerts.router, prefix="/api")
app.include_router(sync.router, prefix="/api")
app.include_router(suppliers.router, prefix="/api")
app.include_router(dashboard.router, prefix="/api")
app.include_router(users.router, prefix="/api")
app.include_router(ai.router, prefix="/api")


def _status_payload() -> dict[str, str]:
    return {"status": "ok", "service": "nasij-mobile-backend"}


@app.get("/health")
async def health_root():
    return _status_payload()


@app.get("/ping")
async def ping_root():
    return {"ping": "pong", "service": "nasij-mobile-backend"}


@app.get("/api/health")
async def health_api():
    return _status_payload()


@app.get("/api/ping")
async def ping_api():
    return {"ping": "pong", "service": "nasij-mobile-backend"}


@app.get("/kaithhealthcheck")
@app.get("/kaithheathcheck")
async def leapcell_health():
    return {"status": "ok"}
