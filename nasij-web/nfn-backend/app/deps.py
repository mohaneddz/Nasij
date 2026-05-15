from supabase import create_client, Client
from fastapi import Depends, HTTPException, Header
from typing import Optional

from app.config import get_settings, Settings


def get_supabase(settings: Settings = Depends(get_settings)) -> Client:
    """Admin client using service role key for backend operations."""
    return create_client(settings.supabase_url, settings.supabase_service_role_key)


def get_anon_supabase(settings: Settings = Depends(get_settings)) -> Client:
    """Anon client for auth operations that respect RLS."""
    return create_client(settings.supabase_url, settings.supabase_anon_key)


async def get_current_user(
    authorization: Optional[str] = Header(None),
    settings: Settings = Depends(get_settings),
) -> dict:
    """Extract and validate Supabase JWT from Authorization header."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid token")

    token = authorization.replace("Bearer ", "")
    client = create_client(settings.supabase_url, settings.supabase_anon_key)

    try:
        user_response = client.auth.get_user(token)
        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid token")
        return {
            "id": str(user_response.user.id),
            "email": user_response.user.email,
            "phone": user_response.user.phone,
            "metadata": user_response.user.user_metadata or {},
        }
    except Exception as exc:
        raise HTTPException(status_code=401, detail=f"Token validation failed: {exc}")
