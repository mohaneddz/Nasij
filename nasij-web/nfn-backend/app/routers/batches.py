from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client
from typing import Optional
from uuid import uuid4

from app.deps import get_supabase
from app.schemas import (
    BatchCreate,
    BatchUpdate,
    BatchResponse,
    AlertCreate,
    AlertSeverity,
)

router = APIRouter(prefix="/batches", tags=["batches"])


def _check_auto_alerts(batch_data: dict, update: BatchUpdate, sb: Client):
    """Generate alerts automatically when thresholds are breached."""
    alerts_to_create = []

    # E1: Weight loss in transit (declared vs received at D1)
    raw = batch_data.get("weight_raw_e1_kg") or 0
    clean = update.weight_after_handclean_kg
    if raw > 0 and clean is not None and clean > 0:
        loss = ((raw - clean) / raw) * 100
        if loss > 20:
            alerts_to_create.append({
                "id": str(uuid4()),
                "batch_id": batch_data["batch_id"],
                "alert_type": "E1_PERTE_EN_ROUTE",
                "severity": "POINT_NOIR",
                "is_resolved": False,
                "description": (
                    f"Batch {batch_data['batch_id']}. "
                    f"Collector declared {raw}kg at farm. "
                    f"D1 Worker received {clean}kg. "
                    f"{raw - clean:.0f}kg missing."
                ),
            })

    # A1: Massive drop during hand-cleaning (C2 source fraud detection)
    handclean = batch_data.get("weight_after_handclean_kg") or 0
    d2_clean = update.weight_clean_d2_kg
    if handclean > 0 and d2_clean is not None and d2_clean > 0:
        drop = ((handclean - d2_clean) / handclean) * 100
        if drop > 60:
            alerts_to_create.append({
                "id": str(uuid4()),
                "batch_id": batch_data["batch_id"],
                "alert_type": "A1_RENDEMENT_FAIBLE",
                "severity": "POINT_ROUGE",
                "is_resolved": False,
                "description": (
                    f"Batch {batch_data['batch_id']} "
                    f"(Source {batch_data.get('source_type', '?')}). "
                    f"Weight before hand-cleaning: {handclean}kg. "
                    f"Weight after: {d2_clean}kg. "
                    f"Massive {drop:.0f}% drop."
                ),
            })

    # Annex: pile temperature / auto-combustion risk.
    if update.temperature_tas_celsius is not None and update.temperature_tas_celsius >= 45:
        alerts_to_create.append({
            "id": str(uuid4()),
            "batch_id": batch_data["batch_id"],
            "alert_type": "ALERTE_AUTO_COMBUSTION",
            "severity": "POINT_ROUGE",
            "is_resolved": False,
            "description": (
                f"Lot {batch_data['batch_id']} (Depot D1). "
                f"Temperature du tas critique ({update.temperature_tas_celsius}C). "
                "Risque d'incendie ou pourriture."
            ),
            "action": "Isoler le lot",
        })

    # Annex: vegetable matter threshold.
    if update.taux_matiere_vegetale_percent is not None and update.taux_matiere_vegetale_percent > 5:
        alerts_to_create.append({
            "id": str(uuid4()),
            "batch_id": batch_data["batch_id"],
            "alert_type": "ALERTE_MATIERES_VEGETALES",
            "severity": "POINT_JAUNE",
            "is_resolved": False,
            "description": (
                f"Lot {batch_data['batch_id']}. "
                "Taux de paille > 5%. Action auto: Redirige vers Classe B (Engrais)."
            ),
            "action": "Rediriger Classe B",
        })

    # Annex 2: source-specific yield thresholds.
    raw_for_yield = batch_data.get("weight_raw_e1_kg") or update.weight_raw_e1_kg or 0
    if raw_for_yield > 0 and d2_clean is not None and d2_clean > 0:
        yield_percent = (d2_clean / raw_for_yield) * 100
        source = batch_data.get("source_type")
        min_expected = 55 if source == "C1" else 35 if source == "C2" else None
        if min_expected is not None and yield_percent < min_expected:
            alerts_to_create.append({
                "id": str(uuid4()),
                "batch_id": batch_data["batch_id"],
                "alert_type": "ALERTE_RENDEMENT_INTELLIGENT",
                "severity": "POINT_ROUGE",
                "is_resolved": False,
                "description": (
                    f"Lot {batch_data['batch_id']} ({source}). "
                    f"Rendement actuel: {yield_percent:.0f}%. "
                    f"Anomalie: Le rendement doit etre > {min_expected}%."
                ),
                "action": "Controle fournisseur",
            })

    for alert in alerts_to_create:
        try:
            sb.table("alerts").insert(alert).execute()
        except Exception:
            pass


@router.get("", response_model=list[BatchResponse])
async def list_batches(
    status: Optional[str] = Query(None),
    breed: Optional[str] = Query(None),
    wilaya: Optional[str] = Query(None),
    sb: Client = Depends(get_supabase),
):
    """List all batches with optional filters."""
    query = sb.table("batches").select("*").order("synced_at", desc=True)

    if status:
        query = query.eq("status", status)
    if breed:
        query = query.eq("breed", breed)
    if wilaya:
        query = query.ilike("wilaya", f"%{wilaya}%")

    result = query.execute()
    return result.data or []


@router.get("/pipeline")
async def pipeline_view(sb: Client = Depends(get_supabase)):
    """Batches grouped by pipeline stage for the Kanban view."""
    result = sb.table("batches").select("*").order("synced_at", desc=True).execute()
    rows = result.data or []

    pipeline = {
        "COLLECTE": [],
        "D1": [],
        "D2": [],
        "TRANSFORMATION": [],
        "READY": [],
    }

    status_map = {
        "PENDING_PICKUP": "COLLECTE",
        "COLLECTED_BY_BUYER": "COLLECTE",
        "AT_D1_STOCKAGE": "D1",
        "AT_D2_LAVAGE": "D2",
        "IN_TRANSFORMATION": "TRANSFORMATION",
        "READY_FOR_SALE": "READY",
    }

    for row in rows:
        key = status_map.get(row.get("status"), "COLLECTE")
        pipeline[key].append(row)

    return pipeline


@router.get("/{batch_id}", response_model=BatchResponse)
async def get_batch(batch_id: str, sb: Client = Depends(get_supabase)):
    """Get a single batch with full traceability data."""
    result = sb.table("batches").select("*").eq("batch_id", batch_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail=f"Batch {batch_id} not found")
    return result.data[0]


@router.post("", response_model=BatchResponse, status_code=201)
async def create_batch(body: BatchCreate, sb: Client = Depends(get_supabase)):
    """Create a new batch from a mobile collection event."""
    row = {
        "batch_id": body.batch_id,
        "source_type": body.source_type,
        "breed": body.breed.value,
        "wilaya": body.wilaya,
        "status": "PENDING_PICKUP",
        "creator_phone": body.creator_phone,
        "collector_phone": body.collector_phone,
        "purchase_price_dzd": body.purchase_price_dzd,
        "type_de_laine": body.type_de_laine.value if body.type_de_laine else None,
        "proprete_score": body.proprete_score,
        "sacs_count": body.sacs_count,
        "weight_raw_e1_kg": body.weight_raw_e1_kg,
        "location_lat": body.location_lat,
        "location_lng": body.location_lng,
        "action_timestamp": body.action_timestamp,
        "annex_metadata": body.annex_metadata,
    }

    row = {k: v for k, v in row.items() if v is not None}

    try:
        result = sb.table("batches").insert(row).execute()
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    return result.data[0]


@router.patch("/{batch_id}", response_model=BatchResponse)
async def update_batch(batch_id: str, body: BatchUpdate, sb: Client = Depends(get_supabase)):
    """Update a batch (advance pipeline stage, add measurements)."""
    existing = sb.table("batches").select("*").eq("batch_id", batch_id).execute()
    if not existing.data:
        raise HTTPException(status_code=404, detail=f"Batch {batch_id} not found")

    update_data = body.model_dump(exclude_none=True, mode="json")
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")

    _check_auto_alerts(existing.data[0], body, sb)

    result = sb.table("batches").update(update_data).eq("batch_id", batch_id).execute()
    return result.data[0]
