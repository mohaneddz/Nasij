from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import auth, batches, alerts, dashboard, sync, users


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    print(f"[NFN] Backend started — Supabase: {settings.supabase_url}")
    print(f"[NFN] CORS origins: {settings.cors_origin_list}")
    yield
    print("[NFN] Backend shutting down")


app = FastAPI(
    title="NASIJ NFN API",
    description="Backend API for the NFN Control Tower — wool traceability platform",
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
app.include_router(dashboard.router, prefix="/api")
app.include_router(sync.router, prefix="/api")
app.include_router(users.router, prefix="/api")


def _status_payload() -> dict[str, str]:
    return {"status": "ok", "service": "nfn-backend"}


@app.get("/health")
async def health_root():
    return _status_payload()


@app.get("/ping")
async def ping_root():
    return {"ping": "pong", "service": "nfn-backend"}


@app.get("/api/health")
async def health_api():
    return _status_payload()


@app.get("/api/ping")
async def ping_api():
    return {"ping": "pong", "service": "nfn-backend"}
