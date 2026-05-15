from fastapi import APIRouter, Depends, Query
from supabase import Client
from typing import Optional
from uuid import uuid4
from datetime import datetime, timezone

from app.deps import get_supabase
from app.schemas import SyncPayload, SyncResult, BatchResponse

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("", response_model=SyncResult)
async def bulk_sync(payload: SyncPayload, sb: Client = Depends(get_supabase)):
    """
    Offline outbox flush — receives all queued actions from the device.
    Uses upsert so re-sending the same batch_id is safe.
    Alert checks run here too so no action is missed even in offline batches.
    """
    synced = 0
    failed = 0
    errors: list[str] = []

    for item in payload.items:
        row: dict = {
            "batch_id": item.batch_id,
            "source_type": item.source_type.value,
            "breed": item.breed.value,
            "wilaya": item.wilaya,
            "status": item.status.value,
            "creator_id": item.creator_id,
            "collector_id": item.collector_id,
            "purchase_price_dzd": item.purchase_price_dzd,
            "type_de_laine": item.type_de_laine.value if item.type_de_laine else None,
            "proprete_score": item.proprete_score,
            "sacs_count": item.sacs_count,
            "weight_raw_e1_kg": item.weight_raw_e1_kg,
            "weight_after_handclean_kg": item.weight_after_handclean_kg,
            "weight_clean_d2_kg": item.weight_clean_d2_kg,
            "stockage_zone": item.stockage_zone,
            "classification": item.classification.value if item.classification else None,
            "temperature_tas_celsius": item.temperature_tas_celsius,
            "taux_matiere_vegetale_percent": item.taux_matiere_vegetale_percent,
            "humidite_sortie_percent": item.humidite_sortie_percent,
            "ph_laine": item.ph_laine,
            "fiber_length_mm": item.fiber_length_mm,
            "finesse_micron": item.finesse_micron,
            "humidity_percent": item.humidity_percent,
            "final_destination": item.final_destination,
            "is_ready_for_sale": item.is_ready_for_sale,
            "location_lat": item.location_lat,
            "location_lng": item.location_lng,
            "action_timestamp": item.action_timestamp,
            "annex_metadata": item.annex_metadata or {},
            "synced_at": datetime.now(timezone.utc).isoformat(),
        }
        row = {k: v for k, v in row.items() if v is not None}

        try:
            sb.table("batches").upsert(row, on_conflict="batch_id").execute()
            synced += 1

            _run_alert_checks(sb, item)

        except Exception as exc:
            failed += 1
            errors.append(f"{item.batch_id}: {exc}")

    return SyncResult(synced=synced, failed=failed, errors=errors)


@router.get("/pending", response_model=list[BatchResponse])
async def pending_delta(
    since: Optional[str] = Query(None, description="ISO timestamp — returns records synced after this time"),
    sb: Client = Depends(get_supabase),
):
    """
    Delta pull — mobile calls this on reconnect to get records updated while offline.
    Returns all batches whose synced_at > since.
    """
    query = sb.table("batches").select("*").order("synced_at", desc=True)
    if since:
        query = query.gt("synced_at", since)
    return query.execute().data or []


def _run_alert_checks(sb: Client, item) -> None:
    """Alert checks applied to offline-synced items — mirrors the online batch logic."""
    raw = item.weight_raw_e1_kg or 0
    after = item.weight_after_handclean_kg or 0
    clean = item.weight_clean_d2_kg or 0

    # E1: weight loss in transit
    if raw > 0 and after > 0:
        loss_pct = ((raw - after) / raw) * 100
        if loss_pct > 20:
            _insert_alert(
                sb,
                item.batch_id,
                "E1_PERTE_EN_ROUTE",
                "POINT_NOIR",
                (
                    f"Lot {item.batch_id}: declare {raw}kg, recu {after}kg — "
                    f"{raw - after:.1f}kg manquants ({loss_pct:.0f}%)."
                ),
                "Verification du collecteur",
            )

    # A1: yield after hand-cleaning
    if raw > 0 and after > 0:
        yield_ratio = after / raw
        min_yield = 0.35 if item.source_type.value == "C2" else 0.55
        if yield_ratio < min_yield:
            _insert_alert(
                sb,
                item.batch_id,
                "A1_RENDEMENT",
                "POINT_ROUGE",
                (
                    f"Lot {item.batch_id} ({item.source_type.value}): rendement {yield_ratio * 100:.1f}% "
                    f"< seuil {min_yield * 100:.0f}%."
                ),
                "Verifier D1",
            )

    # Auto-combustion
    if item.temperature_tas_celsius is not None and item.temperature_tas_celsius >= 45:
        _insert_alert(
            sb,
            item.batch_id,
            "ALERTE_AUTO_COMBUSTION",
            "POINT_ROUGE",
            f"Lot {item.batch_id}: temperature {item.temperature_tas_celsius}C — risque incendie.",
            "Isoler le lot",
        )

    # Vegetable matter
    if item.taux_matiere_vegetale_percent is not None and item.taux_matiere_vegetale_percent > 5:
        _insert_alert(
            sb,
            item.batch_id,
            "ALERTE_MATIERES_VEGETALES",
            "POINT_JAUNE",
            f"Lot {item.batch_id}: paille {item.taux_matiere_vegetale_percent:.1f}% — Classe B.",
            "Rediriger Classe B",
        )

    # Incoherent weight
    if after > 0 and clean > 0 and clean > after:
        _insert_alert(
            sb,
            item.batch_id,
            "E2_INCOHERENT_POIDS",
            "POINT_NOIR",
            f"Lot {item.batch_id}: poids apres lavage ({clean}kg) > apres nettoyage ({after}kg).",
            "Recontrole lavage",
        )


def _insert_alert(sb: Client, batch_id: str, alert_type: str, severity: str, description: str, action: str):
    try:
        existing = (
            sb.table("alerts")
            .select("id")
            .eq("batch_id", batch_id)
            .eq("alert_type", alert_type)
            .eq("is_resolved", False)
            .execute()
        )
        if existing.data:
            return
        sb.table("alerts").insert({
            "id": str(uuid4()),
            "batch_id": batch_id,
            "alert_type": alert_type,
            "severity": severity,
            "description": description,
            "action": action,
            "is_resolved": False,
        }).execute()
    except Exception:
        pass
