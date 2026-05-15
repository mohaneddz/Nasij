from supabase import create_client, Client
from fastapi import Depends, HTTPException, Header
from typing import Optional

from app.config import get_settings, Settings

_supabase_client: Client | None = None
_anon_supabase_client: Client | None = None


def get_supabase(settings: Settings = Depends(get_settings)) -> Client:
    global _supabase_client
    if _supabase_client is None:
        _supabase_client = create_client(settings.supabase_url, settings.supabase_service_role_key)
    return _supabase_client


def get_anon_supabase(settings: Settings = Depends(get_settings)) -> Client:
    global _anon_supabase_client
    if _anon_supabase_client is None:
        _anon_supabase_client = create_client(settings.supabase_url, settings.supabase_anon_key)
    return _anon_supabase_client


async def get_current_user(
    authorization: Optional[str] = Header(None),
    settings: Settings = Depends(get_settings),
) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid token")

    token = authorization.replace("Bearer ", "")

    global _anon_supabase_client, _supabase_client
    if _anon_supabase_client is None:
        _anon_supabase_client = create_client(settings.supabase_url, settings.supabase_anon_key)
    if _supabase_client is None:
        _supabase_client = create_client(settings.supabase_url, settings.supabase_service_role_key)

    try:
        user_response = _anon_supabase_client.auth.get_user(token)
        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid token")

        uid = str(user_response.user.id)
        metadata = user_response.user.user_metadata or {}

        profile = _supabase_client.table("users").select("sector,wilaya,full_name,phone_number,is_approved").eq("id", uid).execute()
        profile_data = profile.data[0] if profile.data else {}

        sector = profile_data.get("sector") or metadata.get("sector")
        
        if profile_data.get("is_approved") is False:
            if sector not in {"C1_FARMER", "C2_ABATTOIR", "C3_AGGREGATOR"}:
                print(f"DEBUG 403: User {uid} is_approved=False (Worker)")
                raise HTTPException(status_code=403, detail="Account pending approval")

        return {
            "id": uid,
            "phone": profile_data.get("phone_number") or metadata.get("phone", ""),
            "sector": sector,
            "wilaya": profile_data.get("wilaya") or metadata.get("wilaya"),
            "full_name": profile_data.get("full_name"),
        }
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=401, detail=f"Token validation failed: {exc}")
