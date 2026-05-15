from fastapi import APIRouter, Depends, HTTPException
from supabase import Client

from app.deps import get_anon_supabase, get_supabase
from app.schemas import AuthSignup, AuthLogin, AuthResponse

router = APIRouter(prefix="/auth", tags=["auth"])


def _normalize_nfn_email(identifier: str) -> str:
    value = (identifier or "").strip().lower()
    if "@" in value:
        return value
    return f"{value}@nfn.local"


@router.post("/signup", response_model=AuthResponse)
async def signup(body: AuthSignup, sb: Client = Depends(get_anon_supabase), admin_sb: Client = Depends(get_supabase)):
    """Register a new user with phone number and sector role."""
    email = _normalize_nfn_email(body.phone)

    try:
        auth_res = sb.auth.sign_up({
            "email": email,
            "password": body.password,
            "options": {
                "data": {
                    "phone": body.phone,
                    "sector": body.sector.value,
                    "wilaya": body.wilaya or "",
                }
            }
        })
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    if not auth_res.session:
        raise HTTPException(status_code=400, detail="Signup failed — check if user already exists")

    # Insert into custom users table
    try:
        admin_sb.table("users").upsert({
            "id": str(auth_res.user.id),
            "phone_number": body.phone,
            "sector": body.sector.value,
            "wilaya": body.wilaya or "",
        }).execute()
    except Exception:
        pass

    return AuthResponse(
        access_token=auth_res.session.access_token,
        refresh_token=auth_res.session.refresh_token,
        user_id=str(auth_res.user.id),
        phone=body.phone,
        sector=body.sector.value,
        wilaya=body.wilaya,
    )


@router.post("/login", response_model=AuthResponse)
async def login(body: AuthLogin, sb: Client = Depends(get_anon_supabase)):
    """Authenticate with phone number and password."""
    email = _normalize_nfn_email(body.phone)

    try:
        auth_res = sb.auth.sign_in_with_password({
            "email": email,
            "password": body.password,
        })
    except Exception as exc:
        raise HTTPException(status_code=401, detail=f"Login failed: {exc}")

    if not auth_res.session:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    metadata = auth_res.user.user_metadata or {}

    return AuthResponse(
        access_token=auth_res.session.access_token,
        refresh_token=auth_res.session.refresh_token,
        user_id=str(auth_res.user.id),
        phone=metadata.get("phone", body.phone),
        sector=metadata.get("sector"),
        wilaya=metadata.get("wilaya"),
    )


@router.post("/logout")
async def logout(sb: Client = Depends(get_anon_supabase)):
    """Sign out the current session."""
    try:
        sb.auth.sign_out()
    except Exception:
        pass
    return {"detail": "Logged out"}
