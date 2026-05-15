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
    sb: Client = Depends(get_supabase),
):
    """List all alerts, optionally filtered by severity or resolved status."""
    query = sb.table("alerts").select("*").order("created_at", desc=True)

    if severity:
        query = query.eq("severity", severity)
    if resolved is not None:
        query = query.eq("is_resolved", resolved)

    result = query.execute()

    rows = result.data or []
    for row in rows:
        if "severity" not in row or not row["severity"]:
            alert_type = row.get("alert_type", "")
            row["severity"] = "POINT_NOIR" if "E1" in alert_type else "POINT_ROUGE"
        if "action" not in row or not row["action"]:
            alert_type = row.get("alert_type", "")
            row["action"] = "Investigate Route" if "E1" in alert_type else "Flag Supplier"
        if "is_resolved" not in row:
            row["is_resolved"] = False

    return rows


@router.patch("/{alert_id}/resolve", response_model=AlertResponse)
async def resolve_alert(alert_id: str, sb: Client = Depends(get_supabase)):
    """Mark an alert as resolved."""
    result = sb.table("alerts").update({"is_resolved": True}).eq("id", alert_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail=f"Alert {alert_id} not found")
    row = result.data[0]
    if "severity" not in row or not row["severity"]:
        alert_type = row.get("alert_type", "")
        row["severity"] = "POINT_NOIR" if "E1" in alert_type else "POINT_ROUGE"
    if "action" not in row or not row["action"]:
        row["action"] = "Investigate Route" if "E1" in row.get("alert_type", "") else "Flag Supplier"
    return row
