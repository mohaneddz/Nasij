from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client

from app.deps import get_current_user, get_supabase
from app.schemas import (
    SectorRole,
    SupplierApprovalActionBody,
    SupplierApprovalQueueItem,
    SupplierApprovalStatus,
    SupplierDeclarationBody,
    SupplierOperationCancelBody,
    SupplierOperationResponse,
    SupplierOperationStatus,
    SupplierProfileResponse,
)

router = APIRouter(prefix="/suppliers", tags=["suppliers"])

_SUPPLIER_SECTORS = {
    SectorRole.C1_FARMER.value,
    SectorRole.C2_ABATTOIR.value,
    SectorRole.C3_AGGREGATOR.value,
}
_ASSIGNED_CANCEL_TRUST_PENALTY = 10


def _to_iso(value) -> str | None:
    if value is None:
        return None
    if isinstance(value, str):
        return value
    return str(value)


def _to_supplier_operation_response(
    row: dict,
    trust_score_after: int | None = None,
) -> SupplierOperationResponse:
    raw_status = row.get("status") or SupplierOperationStatus.PENDING.value
    status_value = (
        SupplierOperationStatus(raw_status)
        if raw_status in {s.value for s in SupplierOperationStatus}
        else SupplierOperationStatus.PENDING
    )
    return SupplierOperationResponse(
        id=str(row["id"]),
        supplier_id=str(row.get("supplier_id") or ""),
        supplier_phone=row.get("supplier_phone") or "",
        supplier_role=row.get("supplier_role") or "",
        status=status_value,
        quantity_count=row.get("quantity_count"),
        quantity_weight_kg=row.get("quantity_weight_kg"),
        location_lat=row.get("location_lat"),
        location_lng=row.get("location_lng"),
        collector_id=row.get("collector_id"),
        collector_phone=row.get("collector_phone"),
        cancel_reason=row.get("cancel_reason"),
        cancelled_at=_to_iso(row.get("cancelled_at")),
        trust_penalty_applied=int(row.get("trust_penalty_applied") or 0),
        trust_score_after=trust_score_after,
        created_at=_to_iso(row.get("created_at")),
        updated_at=_to_iso(row.get("updated_at")),
    )


def _require_manager(current_user: dict) -> None:
    if current_user.get("sector") != SectorRole.MANAGER.value:
        raise HTTPException(status_code=403, detail="Manager role required")


def _require_supplier(current_user: dict) -> None:
    if current_user.get("sector") not in _SUPPLIER_SECTORS:
        print(f"DEBUG 403: User sector {current_user.get('sector')} not in {_SUPPLIER_SECTORS}")
        raise HTTPException(status_code=403, detail="Supplier role required")


def _get_profile(sb: Client, user_id: str) -> dict:
    profile_res = sb.table("users").select("*").eq("id", user_id).limit(1).execute()
    if not profile_res.data:
        raise HTTPException(status_code=404, detail="Supplier profile not found")
    return profile_res.data[0]


@router.get("/me", response_model=SupplierProfileResponse)
async def supplier_me(
    sb: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
):
    _require_supplier(current_user)
    profile = _get_profile(sb, current_user["id"])
    approval_raw = profile.get("approval_status") or SupplierApprovalStatus.APPROVED.value
    approval_status = (
        SupplierApprovalStatus(approval_raw)
        if approval_raw in {s.value for s in SupplierApprovalStatus}
        else SupplierApprovalStatus.APPROVED
    )
    return SupplierProfileResponse(
        id=str(profile["id"]),
        phone=profile.get("phone_number") or current_user.get("phone") or "",
        full_name=profile.get("full_name"),
        sector=profile.get("sector"),
        wilaya=profile.get("wilaya"),
        approval_status=approval_status,
        trust_score=int(profile.get("trust_score") or 100),
    )


@router.post("/declarations", response_model=SupplierOperationResponse, status_code=201)
async def create_declaration(
    body: SupplierDeclarationBody,
    sb: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
):
    _require_supplier(current_user)
    profile = _get_profile(sb, current_user["id"])
    approval_status = profile.get("approval_status") or SupplierApprovalStatus.APPROVED.value
    if approval_status != SupplierApprovalStatus.APPROVED.value:
        print(f"DEBUG 403: User {current_user['id']} approval_status is {approval_status}")
        raise HTTPException(
            status_code=403,
            detail="Supplier is pending approval",
        )

    sector = profile.get("sector") or current_user.get("sector")
    if sector == SectorRole.C1_FARMER.value and body.quantity_count is None:
        raise HTTPException(status_code=422, detail="Farmers must provide quantity_count")
    if sector == SectorRole.C3_AGGREGATOR.value and body.quantity_weight_kg is None:
        raise HTTPException(status_code=422, detail="Producers must provide quantity_weight_kg")
    if sector == SectorRole.C2_ABATTOIR.value and (
        body.quantity_count is None and body.quantity_weight_kg is None
    ):
        raise HTTPException(
            status_code=422,
            detail="Slaughterhouse must provide quantity_count or quantity_weight_kg",
        )

    operation_payload = {
        "supplier_id": current_user["id"],
        "supplier_phone": profile.get("phone_number") or current_user.get("phone"),
        "supplier_role": sector,
        "status": SupplierOperationStatus.PENDING.value,
        "quantity_count": body.quantity_count,
        "quantity_weight_kg": body.quantity_weight_kg,
        "location_lat": body.location_lat,
        "location_lng": body.location_lng,
    }
    operation_payload = {k: v for k, v in operation_payload.items() if v is not None}
    created = sb.table("supplier_operations").insert(operation_payload).execute()
    return _to_supplier_operation_response(created.data[0])


@router.get("/operations", response_model=list[SupplierOperationResponse])
async def list_supplier_operations(
    include_history: bool = Query(False),
    sb: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
):
    _require_supplier(current_user)
    query = (
        sb.table("supplier_operations")
        .select("*")
        .eq("supplier_id", current_user["id"])
        .order("created_at", desc=True)
    )
    if not include_history:
        query = query.in_(
            "status",
            [
                SupplierOperationStatus.PENDING.value,
                SupplierOperationStatus.ASSIGNED.value,
            ],
        )
    result = query.execute()
    return [_to_supplier_operation_response(row) for row in (result.data or [])]


@router.post(
    "/operations/{operation_id}/cancel",
    response_model=SupplierOperationResponse,
)
async def cancel_supplier_operation(
    operation_id: str,
    body: SupplierOperationCancelBody,
    sb: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
):
    _require_supplier(current_user)
    existing = (
        sb.table("supplier_operations")
        .select("*")
        .eq("id", operation_id)
        .eq("supplier_id", current_user["id"])
        .limit(1)
        .execute()
    )
    if not existing.data:
        raise HTTPException(status_code=404, detail="Operation not found")
    operation = existing.data[0]
    status = operation.get("status")
    if status in {
        SupplierOperationStatus.CANCELLED_PENDING.value,
        SupplierOperationStatus.CANCELLED_ASSIGNED.value,
        SupplierOperationStatus.COMPLETED.value,
    }:
        raise HTTPException(status_code=409, detail="Operation is not cancellable")

    trust_penalty = 0
    next_status = SupplierOperationStatus.CANCELLED_PENDING.value
    if status == SupplierOperationStatus.ASSIGNED.value:
        if not body.call_confirmed:
            raise HTTPException(
                status_code=400,
                detail="Assigned operations require call confirmation",
            )
        next_status = SupplierOperationStatus.CANCELLED_ASSIGNED.value
        trust_penalty = _ASSIGNED_CANCEL_TRUST_PENALTY

    now_iso = datetime.now(timezone.utc).isoformat()
    update_payload = {
        "status": next_status,
        "cancel_reason": body.reason or "",
        "cancelled_at": now_iso,
        "updated_at": now_iso,
        "trust_penalty_applied": trust_penalty,
    }
    updated = (
        sb.table("supplier_operations")
        .update(update_payload)
        .eq("id", operation_id)
        .eq("supplier_id", current_user["id"])
        .execute()
    )
    if not updated.data:
        raise HTTPException(status_code=500, detail="Failed to cancel operation")

    trust_after: int | None = None
    if trust_penalty > 0:
        profile = _get_profile(sb, current_user["id"])
        current_trust = int(profile.get("trust_score") or 100)
        trust_after = max(0, current_trust - trust_penalty)
        sb.table("users").update({"trust_score": trust_after}).eq(
            "id", current_user["id"]
        ).execute()

    return _to_supplier_operation_response(updated.data[0], trust_score_after=trust_after)


@router.get("/pending-approvals", response_model=list[SupplierApprovalQueueItem])
async def list_pending_supplier_approvals(
    status: SupplierApprovalStatus = Query(SupplierApprovalStatus.PENDING_APPROVAL),
    limit: int = Query(100, ge=1, le=500),
    sb: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
):
    _require_manager(current_user)
    query = (
        sb.table("users")
        .select("*")
        .in_("sector", list(_SUPPLIER_SECTORS))
        .eq("approval_status", status.value)
        .order("approval_requested_at", desc=True)
        .limit(limit)
    )
    rows = query.execute().data or []
    return [
        SupplierApprovalQueueItem(
            id=str(row["id"]),
            phone=row.get("phone_number") or "",
            full_name=row.get("full_name"),
            sector=row.get("sector"),
            wilaya=row.get("wilaya"),
            approval_status=(
                SupplierApprovalStatus(row.get("approval_status"))
                if row.get("approval_status") in {s.value for s in SupplierApprovalStatus}
                else SupplierApprovalStatus.PENDING_APPROVAL
            ),
            approval_requested_at=_to_iso(row.get("approval_requested_at")),
            approval_decided_at=_to_iso(row.get("approval_decided_at")),
            approval_note=row.get("approval_note"),
            trust_score=int(row.get("trust_score") or 100),
        )
        for row in rows
    ]


@router.post("/{supplier_id}/approve", response_model=SupplierProfileResponse)
async def approve_supplier(
    supplier_id: str,
    body: SupplierApprovalActionBody,
    sb: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
):
    _require_manager(current_user)
    now_iso = datetime.now(timezone.utc).isoformat()
    updated = (
        sb.table("users")
        .update(
            {
                "approval_status": SupplierApprovalStatus.APPROVED.value,
                "approval_decided_at": now_iso,
                "approval_decided_by": current_user["id"],
                "approval_note": body.note or "",
            }
        )
        .eq("id", supplier_id)
        .execute()
    )
    if not updated.data:
        raise HTTPException(status_code=404, detail="Supplier not found")
    row = updated.data[0]
    return SupplierProfileResponse(
        id=str(row["id"]),
        phone=row.get("phone_number") or "",
        full_name=row.get("full_name"),
        sector=row.get("sector"),
        wilaya=row.get("wilaya"),
        approval_status=SupplierApprovalStatus.APPROVED,
        trust_score=int(row.get("trust_score") or 100),
    )


@router.post("/{supplier_id}/reject", response_model=SupplierProfileResponse)
async def reject_supplier(
    supplier_id: str,
    body: SupplierApprovalActionBody,
    sb: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
):
    _require_manager(current_user)
    now_iso = datetime.now(timezone.utc).isoformat()
    updated = (
        sb.table("users")
        .update(
            {
                "approval_status": SupplierApprovalStatus.REJECTED.value,
                "approval_decided_at": now_iso,
                "approval_decided_by": current_user["id"],
                "approval_note": body.note or "",
            }
        )
        .eq("id", supplier_id)
        .execute()
    )
    if not updated.data:
        raise HTTPException(status_code=404, detail="Supplier not found")
    row = updated.data[0]
    return SupplierProfileResponse(
        id=str(row["id"]),
        phone=row.get("phone_number") or "",
        full_name=row.get("full_name"),
        sector=row.get("sector"),
        wilaya=row.get("wilaya"),
        approval_status=SupplierApprovalStatus.REJECTED,
        trust_score=int(row.get("trust_score") or 100),
    )
