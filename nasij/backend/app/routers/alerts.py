from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client
from typing import Optional

from app.deps import get_supabase
from app.schemas import AlertResponse

router = APIRouter(prefix="/alerts", tags=["alerts"])


@router.get("", response_model=list[AlertResponse])
async def list_alerts(
    severity: Optional[str] = Query(None),
    resolved: Optional[bool] = Query(None),
    batch_id: Optional[str] = Query(None),
    sb: Client = Depends(get_supabase),
):
    query = sb.table("alerts").select("*").order("created_at", desc=True)
    if severity:
        query = query.eq("severity", severity)
    if resolved is not None:
        query = query.eq("is_resolved", resolved)
    if batch_id:
        query = query.eq("batch_id", batch_id)

    rows = query.execute().data or []
    for row in rows:
        if not row.get("severity"):
            row["severity"] = "POINT_NOIR" if "E1" in (row.get("alert_type") or "") else "POINT_ROUGE"
        if not row.get("action"):
            row["action"] = "Investigate" if "E1" in (row.get("alert_type") or "") else "Flag"
        row.setdefault("is_resolved", False)
    return rows


@router.get("/my-batches", response_model=list[AlertResponse])
async def alerts_for_user_batches(
    user_id: str = Query(..., description="UUID of the creator"),
    sb: Client = Depends(get_supabase),
):
    """Returns alerts for all batches created by the given user — for the farmer/butcher Home screen."""
    batches_res = sb.table("batches").select("batch_id").eq("creator_id", user_id).execute()
    batch_ids = [b["batch_id"] for b in (batches_res.data or [])]
    if not batch_ids:
        return []

    rows = (
        sb.table("alerts")
        .select("*")
        .in_("batch_id", batch_ids)
        .eq("is_resolved", False)
        .order("created_at", desc=True)
        .execute()
        .data or []
    )
    for row in rows:
        row.setdefault("is_resolved", False)
    return rows


@router.patch("/{alert_id}/resolve", response_model=AlertResponse)
async def resolve_alert(alert_id: str, sb: Client = Depends(get_supabase)):
    result = sb.table("alerts").update({"is_resolved": True}).eq("id", alert_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail=f"Alert {alert_id} not found")
    return result.data[0]
