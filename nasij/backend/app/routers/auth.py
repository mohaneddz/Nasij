import re
from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from supabase import Client

from app.deps import get_anon_supabase, get_supabase, get_current_user
from app.schemas import (
    AuthSignup,
    AuthLogin,
    AuthRefresh,
    AuthResponse,
    EmployeeLoginBody,
    EmployeeAuthResponse,
    MeResponse,
    SectorRole,
    SupplierApprovalStatus,
    SupplierAuthResponse,
    SupplierOtpRequest,
    SupplierOtpRequestResponse,
    SupplierOtpVerify,
    SupplierRole,
)

router = APIRouter(prefix="/auth", tags=["auth"])

_SUPPLIER_OTP_RESEND_SECONDS = 60


def _phone_to_email(phone: str) -> str:
    value = (phone or "").strip().lower()
    if "@" in value:
        return value
    return f"{value}@nfn.local"


def _normalize_phone(phone: str) -> str:
    return re.sub(r"\s+", "", (phone or "").strip())


def _normalize_employee_sector(value: Any) -> str:
    normalized = str(value or "").strip().upper()
    alias_map = {
        "COLLECTOR": "COLLECTOR",
        "COLLECTEUR": "COLLECTOR",
        "C1_FARMER": "COLLECTOR",
        "C1_COLLECTOR": "COLLECTOR",
        "DEPOT_WORKER": SectorRole.DEPOT_WORKER.value,
        "DEPOT": SectorRole.DEPOT_WORKER.value,
        "LAVAGE_WORKER": SectorRole.LAVAGE_WORKER.value,
        "LAVERY": SectorRole.LAVAGE_WORKER.value,
        "LAVOIR": SectorRole.LAVAGE_WORKER.value,
        "TRANSFORMATEUR": SectorRole.TRANSFORMATEUR.value,
        "TRANSFORMATION": SectorRole.TRANSFORMATEUR.value,
        "TRANSFO": SectorRole.TRANSFORMATEUR.value,
    }
    return alias_map.get(normalized, normalized)


def _supplier_password(phone: str) -> str:
    return f"nfn-supplier-otp::{_normalize_phone(phone)}::v1"


def _supplier_role_to_sector(supplier_role: SupplierRole) -> SectorRole:
    if supplier_role == SupplierRole.farmer:
        return SectorRole.C1_FARMER
    if supplier_role == SupplierRole.producer:
        return SectorRole.C3_AGGREGATOR
    return SectorRole.C2_ABATTOIR


def _get_auth_user_by_email(admin_sb: Client, email: str) -> Any | None:
    """Targeted email lookup using the admin API filter parameter."""
    try:
        result = admin_sb.auth.admin.list_users(filter=f"email={email}")
        users = result.users if hasattr(result, 'users') else (result if isinstance(result, list) else [])
        return next((u for u in users if (getattr(u, 'email', '') or '').lower() == email.lower()), None)
    except Exception:
        try:
            result = admin_sb.auth.admin.list_users()
            users = result.users if hasattr(result, 'users') else (result if isinstance(result, list) else [])
            return next((u for u in users if (getattr(u, 'email', '') or '').lower() == email.lower()), None)
        except Exception:
            return None


def _get_auth_user_by_id(admin_sb: Client, user_id: str) -> Any | None:
    try:
        result = admin_sb.auth.admin.list_users()
        users = result.users if hasattr(result, 'users') else (result if isinstance(result, list) else [])
        return next((u for u in users if str(getattr(u, 'id', '')) == str(user_id)), None)
    except Exception:
        return None


def _get_user_profiles_by_phone(admin_sb: Client, phone: str) -> list[dict]:
    profile_res = (
        admin_sb.table("users")
        .select("*")
        .eq("phone_number", phone)
        .execute()
    )
    return list(profile_res.data or [])


def _get_user_profile_by_phone(admin_sb: Client, phone: str) -> dict | None:
    profiles = _get_user_profiles_by_phone(admin_sb, phone)
    if not profiles:
        return None
    if len(profiles) > 1:
        raise HTTPException(
            status_code=409,
            detail=(
                "Duplicate accounts detected for this mobile number. "
                "Please contact support."
            ),
        )
    return profiles[0]


def _get_user_profile_by_id(admin_sb: Client, user_id: str) -> dict | None:
    profile_res = (
        admin_sb.table("users")
        .select("*")
        .eq("id", user_id)
        .limit(1)
        .execute()
    )
    if not profile_res.data:
        return None
    return profile_res.data[0]


def _ensure_supplier_user(
    admin_sb: Client,
    phone: str,
    supplier_role: SupplierRole,
    full_name: str | None = None,
    wilaya: str | None = None,
) -> tuple[dict, bool]:
    normalized_phone = _normalize_phone(phone)
    email = _phone_to_email(normalized_phone)
    password = _supplier_password(normalized_phone)
    sector = _supplier_role_to_sector(supplier_role).value
    now_iso = datetime.now(timezone.utc).isoformat()

    existing_auth = _get_auth_user_by_email(admin_sb, email)
    profile_by_phone = _get_user_profile_by_phone(admin_sb, normalized_phone)

    if profile_by_phone and not existing_auth:
        # Recover legacy profile/account linkage when possible.
        existing_auth = _get_auth_user_by_id(admin_sb, str(profile_by_phone.get("id")))
        if existing_auth is None:
            raise HTTPException(
                status_code=409,
                detail=(
                    "This mobile number is already registered but account mapping is invalid. "
                    "Please contact support."
                ),
            )

    if existing_auth and profile_by_phone and str(profile_by_phone.get("id")) != str(existing_auth.id):
        raise HTTPException(
            status_code=409,
            detail=(
                "This mobile number is linked to another account. "
                "Please contact support."
            ),
        )

    existing_profile = profile_by_phone

    metadata = {
        "phone": normalized_phone,
        "sector": sector,
        "wilaya": (wilaya or "").strip() or (existing_profile or {}).get("wilaya") or "",
        "full_name": (full_name or "").strip() or (existing_profile or {}).get("full_name") or "",
    }

    if existing_auth:
        user_id = str(existing_auth.id)
    else:
        created = admin_sb.auth.admin.create_user(
            {
                "email": email,
                "password": password,
                "email_confirm": True,
                "user_metadata": metadata,
            }
        )
        user_id = str(created.user.id)

    existing_profile = existing_profile or _get_user_profile_by_id(admin_sb, user_id)
    is_new_supplier = existing_profile is None

    resolved_wilaya = (wilaya or "").strip() or (existing_profile or {}).get("wilaya") or ""
    resolved_full_name = (full_name or "").strip() or (existing_profile or {}).get("full_name") or ""

    if existing_auth:
        # Keep auth metadata in sync with resolved profile values.
        admin_sb.auth.admin.update_user_by_id(
            user_id,
            {
                "email": email,
                "password": password,
                "email_confirm": True,
                "user_metadata": {
                    "phone": normalized_phone,
                    "sector": sector,
                    "wilaya": resolved_wilaya,
                    "full_name": resolved_full_name,
                },
            },
        )

    profile_payload: dict[str, Any] = {
        "id": user_id,
        "phone_number": normalized_phone,
        "role": sector,
        "sector": sector,
        "wilaya": resolved_wilaya,
        "full_name": resolved_full_name,
        "trust_score": int((existing_profile or {}).get("trust_score") or 100),
    }

    approval_status = (existing_profile or {}).get("approval_status")
    if is_new_supplier:
        profile_payload["approval_status"] = SupplierApprovalStatus.PENDING_APPROVAL.value
        profile_payload["approval_requested_at"] = now_iso
    elif approval_status:
        profile_payload["approval_status"] = approval_status
    else:
        # Keep legacy users usable without forcing re-approval.
        profile_payload["approval_status"] = SupplierApprovalStatus.APPROVED.value

    if (
        profile_payload["approval_status"] == SupplierApprovalStatus.PENDING_APPROVAL.value
        and not (existing_profile or {}).get("approval_requested_at")
    ):
        profile_payload["approval_requested_at"] = now_iso

    try:
        admin_sb.table("users").upsert(profile_payload).execute()
    except Exception as exc:
        message = str(exc).lower()
        if "duplicate key" in message or "unique" in message:
            raise HTTPException(
                status_code=409,
                detail="This mobile number is already registered.",
            )
        # Fallback for environments where approval/trust columns are not yet migrated.
        admin_sb.table("users").upsert(
            {
                "id": user_id,
                "phone_number": normalized_phone,
                "role": sector,
                "sector": sector,
                "wilaya": resolved_wilaya,
                "full_name": resolved_full_name,
            }
        ).execute()

    refreshed_profile = _get_user_profile_by_id(admin_sb, user_id) or {
        "id": user_id,
        "phone_number": normalized_phone,
        "sector": sector,
        "wilaya": resolved_wilaya,
        "full_name": resolved_full_name,
        "approval_status": SupplierApprovalStatus.PENDING_APPROVAL.value
        if is_new_supplier
        else SupplierApprovalStatus.APPROVED.value,
        "trust_score": int((existing_profile or {}).get("trust_score") or 100),
    }
    return refreshed_profile, is_new_supplier


@router.post("/supplier/request-otp", response_model=SupplierOtpRequestResponse)
async def request_supplier_otp(
    body: SupplierOtpRequest,
    admin_sb: Client = Depends(get_supabase),
):
    normalized_phone = _normalize_phone(body.phone)
    profile, created_new = _ensure_supplier_user(
        admin_sb=admin_sb,
        phone=normalized_phone,
        supplier_role=body.supplier_role,
        full_name=body.full_name,
        wilaya=body.wilaya,
    )
    is_new_supplier = created_new or (
        profile.get("approval_status") == SupplierApprovalStatus.PENDING_APPROVAL.value
        and not profile.get("approval_decided_at")
    )
    return SupplierOtpRequestResponse(
        cooldown_seconds=_SUPPLIER_OTP_RESEND_SECONDS,
        is_new_supplier=is_new_supplier,
    )


@router.post("/supplier/verify-otp", response_model=SupplierAuthResponse)
async def verify_supplier_otp(
    body: SupplierOtpVerify,
    sb: Client = Depends(get_anon_supabase),
    admin_sb: Client = Depends(get_supabase),
):
    normalized_phone = _normalize_phone(body.phone)
    profile, _ = _ensure_supplier_user(
        admin_sb=admin_sb,
        phone=normalized_phone,
        supplier_role=body.supplier_role,
        full_name=body.full_name,
        wilaya=body.wilaya,
    )
    approval_raw = profile.get("approval_status")
    approval_status = (
        SupplierApprovalStatus(approval_raw)
        if approval_raw in {s.value for s in SupplierApprovalStatus}
        else SupplierApprovalStatus.APPROVED
    )
    if approval_status != SupplierApprovalStatus.APPROVED:
        return SupplierAuthResponse(
            approval_status=approval_status,
            message=(
                "We are currently reviewing your supplier request. "
                "Our team will call you to validate your account."
            ),
            phone=normalized_phone,
            sector=profile.get("sector"),
            wilaya=profile.get("wilaya"),
            full_name=profile.get("full_name"),
            trust_score=int(profile.get("trust_score") or 100),
        )

    email = _phone_to_email(normalized_phone)
    try:
        auth_res = sb.auth.sign_in_with_password(
            {
                "email": email,
                "password": _supplier_password(normalized_phone),
            }
        )
    except Exception as exc:
        raise HTTPException(status_code=401, detail=f"Supplier login failed: {exc}")

    if not auth_res.session:
        raise HTTPException(status_code=401, detail="Invalid supplier session")

    return SupplierAuthResponse(
        approval_status=SupplierApprovalStatus.APPROVED,
        access_token=auth_res.session.access_token,
        refresh_token=auth_res.session.refresh_token,
        user_id=str(auth_res.user.id),
        phone=normalized_phone,
        sector=profile.get("sector"),
        wilaya=profile.get("wilaya"),
        full_name=profile.get("full_name"),
        trust_score=int(profile.get("trust_score") or 100),
    )


@router.post("/signup", response_model=AuthResponse, status_code=201)
async def signup(
    body: AuthSignup,
    sb: Client = Depends(get_anon_supabase),
    admin_sb: Client = Depends(get_supabase),
):
    email = _phone_to_email(body.phone)

    try:
        auth_res = sb.auth.sign_up(
            {
                "email": email,
                "password": body.password,
                "options": {
                    "data": {
                        "phone": body.phone,
                        "sector": body.sector.value,
                        "wilaya": body.wilaya or "",
                        "full_name": body.full_name or "",
                    }
                },
            }
        )
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    if not auth_res.session:
        raise HTTPException(
            status_code=400,
            detail="Signup failed — user may already exist",
        )

    try:
        admin_sb.table("users").upsert(
            {
                "id": str(auth_res.user.id),
                "phone_number": body.phone,
                "role": "SUPPLIER",
                "sector": body.sector.value,
                "wilaya": body.wilaya or "",
                "full_name": body.full_name or "",
            }
        ).execute()
    except Exception:
        pass

    return AuthResponse(
        access_token=auth_res.session.access_token,
        refresh_token=auth_res.session.refresh_token,
        user_id=str(auth_res.user.id),
        phone=body.phone,
        sector=body.sector.value,
        wilaya=body.wilaya,
        full_name=body.full_name,
    )


@router.post("/login", response_model=AuthResponse)
async def login(
    body: AuthLogin,
    sb: Client = Depends(get_anon_supabase),
    admin_sb: Client = Depends(get_supabase),
):
    email = _phone_to_email(body.phone)

    try:
        auth_res = sb.auth.sign_in_with_password(
            {"email": email, "password": body.password}
        )
    except Exception as exc:
        raise HTTPException(status_code=401, detail=f"Login failed: {exc}")

    if not auth_res.session:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    uid = str(auth_res.user.id)
    profile_res = (
        admin_sb.table("users")
        .select("sector,wilaya,full_name,phone_number")
        .eq("id", uid)
        .execute()
    )
    profile = profile_res.data[0] if profile_res.data else {}
    
    if profile.get("is_approved") is False:
        raise HTTPException(status_code=403, detail="Account pending approval")

    metadata = auth_res.user.user_metadata or {}

    return AuthResponse(
        access_token=auth_res.session.access_token,
        refresh_token=auth_res.session.refresh_token,
        user_id=uid,
        phone=profile.get("phone_number") or metadata.get("phone", body.phone),
        sector=profile.get("sector") or metadata.get("sector"),
        wilaya=profile.get("wilaya") or metadata.get("wilaya"),
        full_name=profile.get("full_name") or metadata.get("full_name"),
    )


@router.post("/refresh", response_model=AuthResponse)
async def refresh(
    body: AuthRefresh,
    sb: Client = Depends(get_anon_supabase),
    admin_sb: Client = Depends(get_supabase),
):
    try:
        auth_res = sb.auth.refresh_session(body.refresh_token)
    except Exception as exc:
        raise HTTPException(status_code=401, detail=f"Token refresh failed: {exc}")

    if not auth_res.session:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    uid = str(auth_res.user.id)
    profile_res = (
        admin_sb.table("users")
        .select("sector,wilaya,full_name,phone_number")
        .eq("id", uid)
        .execute()
    )
    profile = profile_res.data[0] if profile_res.data else {}
    metadata = auth_res.user.user_metadata or {}

    return AuthResponse(
        access_token=auth_res.session.access_token,
        refresh_token=auth_res.session.refresh_token,
        user_id=uid,
        phone=profile.get("phone_number") or metadata.get("phone", ""),
        sector=profile.get("sector") or metadata.get("sector"),
        wilaya=profile.get("wilaya") or metadata.get("wilaya"),
        full_name=profile.get("full_name") or metadata.get("full_name"),
    )


@router.get("/me", response_model=MeResponse)
async def me(current_user: dict = Depends(get_current_user)):
    return MeResponse(
        id=current_user["id"],
        phone=current_user["phone"],
        sector=current_user.get("sector"),
        wilaya=current_user.get("wilaya"),
        full_name=current_user.get("full_name"),
    )


@router.post("/employee/login", response_model=EmployeeAuthResponse)
async def employee_login(
    body: EmployeeLoginBody,
    sb: Client = Depends(get_anon_supabase),
    admin_sb: Client = Depends(get_supabase),
):
    """
    Phone + password login for company employees (Collector, Depot, Lavery, Transformation).
    Returns the user's sector so the client can route to the correct UI.
    """
    # Allowed employee sectors — must NOT be a supplier sector
    _EMPLOYEE_SECTORS = {
        SectorRole.DEPOT_WORKER.value,
        SectorRole.LAVAGE_WORKER.value,
        SectorRole.TRANSFORMATEUR.value,
        # Collectors are technically C-sector but are employees in this pipeline
        "COLLECTOR",
    }

    normalized_phone = _normalize_phone(body.phone)
    login_email = _phone_to_email(normalized_phone)
    profile_by_phone = _get_user_profile_by_phone(admin_sb, normalized_phone)
    if profile_by_phone:
        auth_user = _get_auth_user_by_id(admin_sb, str(profile_by_phone.get("id")))
        auth_email = (getattr(auth_user, "email", "") or "").strip().lower() if auth_user else ""
        if auth_email:
            login_email = auth_email
    else:
        # Legacy fallback: some employee accounts may only have phone in auth metadata.
        try:
            result = admin_sb.auth.admin.list_users()
            users = result.users if hasattr(result, "users") else (result if isinstance(result, list) else [])
            for user in users:
                metadata = getattr(user, "user_metadata", {}) or {}
                meta_phone = _normalize_phone(str(metadata.get("phone", "")))
                candidate_email = (getattr(user, "email", "") or "").strip().lower()
                if meta_phone == normalized_phone and candidate_email:
                    login_email = candidate_email
                    break
        except Exception:
            pass

    try:
        auth_res = sb.auth.sign_in_with_password(
            {"email": login_email, "password": body.password}
        )
    except Exception:
        raise HTTPException(status_code=401, detail="auth_error_login_failed")

    if not auth_res.session:
        raise HTTPException(status_code=401, detail="auth_error_login_failed")

    uid = str(auth_res.user.id)

    # Fetch the employee profile from the users table
    profile_res = (
        admin_sb.table("users")
        .select("sector,full_name,role,phone_number")
        .eq("id", uid)
        .limit(1)
        .execute()
    )
    profile = profile_res.data[0] if profile_res.data else {}
    metadata = auth_res.user.user_metadata or {}

    # Resolve sector robustly. Prefer explicit sector values over role labels.
    normalized_candidates = [
        _normalize_employee_sector(candidate)
        for candidate in (
            profile.get("sector"),
            profile.get("role"),
            metadata.get("sector"),
            metadata.get("role"),
        )
        if candidate is not None
    ]

    # If any source marks the account as collector, keep collector routing stable.
    if "COLLECTOR" in normalized_candidates:
        sector = "COLLECTOR"
    else:
        sector = next(
            (value for value in normalized_candidates if value in _EMPLOYEE_SECTORS),
            "",
        )

    full_name = profile.get("full_name") or metadata.get("full_name")
    if not sector:
        raise HTTPException(status_code=403, detail="Employee role required")

    return EmployeeAuthResponse(
        access_token=auth_res.session.access_token,
        refresh_token=auth_res.session.refresh_token,
        user_id=uid,
        phone=profile.get("phone_number") or metadata.get("phone") or normalized_phone,
        sector=sector,
        full_name=full_name,
    )


@router.post("/logout")
async def logout(sb: Client = Depends(get_anon_supabase)):
    try:
        sb.auth.sign_out()
    except Exception:
        pass
    return {"detail": "Logged out"}
