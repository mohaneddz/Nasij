from fastapi import APIRouter, Depends, HTTPException
from supabase import Client
from typing import List

from app.deps import get_supabase
from app.schemas import UserCreate, UserResponse

router = APIRouter(prefix="/users", tags=["users"])


def _phone_to_email(phone: str) -> str:
    value = (phone or "").strip().lower()
    if "@" in value:
        return value
    return f"{value}@nfn.local"


@router.post("/staff", response_model=UserResponse, status_code=201)
async def create_staff(
    body: UserCreate,
    admin_sb: Client = Depends(get_supabase),
):
    """Admin creates an internal staff account. Auto-approved."""
    email = _phone_to_email(body.phone)

    try:
        auth_res = admin_sb.auth.admin.create_user({
            "email": email,
            "password": body.password,
            "email_confirm": True,
            "user_metadata": {
                "phone": body.phone,
                "sector": body.sector.value,
                "wilaya": body.wilaya or "",
                "full_name": body.full_name or "",
            }
        })
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    uid = str(auth_res.user.id)

    # Insert into users table
    try:
        admin_sb.table("users").upsert({
            "id": uid,
            "phone_number": body.phone,
            "sector": body.sector.value,
            "role": body.sector.value,
            "wilaya": body.wilaya or "",
            "full_name": body.full_name or "",
            "is_approved": True,
        }).execute()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database insertion failed: {e}")

    # Fetch the final object to return
    user_data = admin_sb.table("users").select("*").eq("id", uid).execute().data[0]

    return UserResponse(
        id=user_data["id"],
        phone_number=user_data["phone_number"],
        full_name=user_data.get("full_name"),
        sector=user_data["sector"],
        wilaya=user_data.get("wilaya"),
        is_approved=user_data.get("is_approved", False),
        created_at=user_data.get("created_at")
    )


@router.get("/pending", response_model=List[UserResponse])
async def list_pending_users(admin_sb: Client = Depends(get_supabase)):
    """Fetch external users waiting for admin approval."""
    res = admin_sb.table("users").select("*").eq("is_approved", False).order("created_at", desc=True).execute()
    return res.data


@router.get("", response_model=List[UserResponse])
async def list_users(admin_sb: Client = Depends(get_supabase)):
    """List users for dashboard enrichment (collector/creator details)."""
    res = admin_sb.table("users").select("*").order("created_at", desc=True).execute()
    return res.data


@router.patch("/{user_id}/approve", response_model=UserResponse)
async def approve_user(user_id: str, admin_sb: Client = Depends(get_supabase)):
    """Approve a pending external account."""
    res = admin_sb.table("users").update({"is_approved": True}).eq("id", user_id).execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="User not found")
    
    return res.data[0]
