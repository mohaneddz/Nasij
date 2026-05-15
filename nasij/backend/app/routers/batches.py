from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client
from typing import Optional
from uuid import uuid4
from datetime import datetime, timezone

from app.deps import get_supabase, get_current_user
from app.schemas import (
    BatchResponse,
    CreateBatchBody,
    CollectBody,
    D1IntakeBody,
    D1CleanBody,
    D2WashBody,
    TransformIntakeBody,
    TransformBody,
    BatchStatus,
)

router = APIRouter(prefix="/batches", tags=["batches"])


def _fire_alert(sb: Client, batch_id: str, alert_type: str, severity: str, description: str, action: str = ""):
    try:
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


def _require_batch(sb: Client, batch_id: str) -> dict:
    res = sb.table("batches").select("*").eq("batch_id", batch_id).execute()
    if not res.data:
        raise HTTPException(status_code=404, detail=f"Batch {batch_id} not found")
    return res.data[0]


def _enrich_batches_with_contacts(sb: Client, rows: list[dict]) -> list[dict]:
    if not rows:
        return []

    user_ids: set[str] = set()
    for row in rows:
        creator_id = row.get("creator_id")
        collector_id = row.get("collector_id")
        if creator_id:
            user_ids.add(str(creator_id))
        if collector_id:
            user_ids.add(str(collector_id))

    users_map: dict[str, dict] = {}
    if user_ids:
        users_res = (
            sb.table("users")
            .select("id,phone_number,full_name")
            .in_("id", list(user_ids))
            .execute()
        )
        users_map = {
            str(user.get("id")): user for user in (users_res.data or [])
        }

    enriched: list[dict] = []
    for row in rows:
        copy = dict(row)
        creator = users_map.get(str(copy.get("creator_id")))
        collector = users_map.get(str(copy.get("collector_id")))
        copy["creator_phone"] = creator.get("phone_number") if creator else None
        copy["creator_full_name"] = creator.get("full_name") if creator else None
        copy["collector_phone"] = collector.get("phone_number") if collector else None
        copy["collector_full_name"] = collector.get("full_name") if collector else None
        enriched.append(copy)
    return enriched


def _enrich_batch_with_contacts(sb: Client, row: dict) -> dict:
    enriched = _enrich_batches_with_contacts(sb, [row])
    return enriched[0] if enriched else row


# ── List / read ──────────────────────────────────────────────────────────────

@router.get("", response_model=list[BatchResponse])
async def list_batches(
    status: Optional[str] = Query(None),
    source_type: Optional[str] = Query(None),
    wilaya: Optional[str] = Query(None),
    breed: Optional[str] = Query(None),
    collector_id: Optional[str] = Query(None),
    sb: Client = Depends(get_supabase),
):
    query = sb.table("batches").select("*").order("synced_at", desc=True)
    if status:
        query = query.eq("status", status)
    if source_type:
        query = query.eq("source_type", source_type)
    if wilaya:
        query = query.ilike("wilaya", f"%{wilaya}%")
    if breed:
        query = query.eq("breed", breed)
    if collector_id:
        query = query.eq("collector_id", collector_id)
    rows = query.execute().data or []
    return _enrich_batches_with_contacts(sb, rows)


@router.get("/pending", response_model=list[BatchResponse])
async def pending_batches(
    wilaya: Optional[str] = Query(None),
    sb: Client = Depends(get_supabase),
):
    """Collector radar — returns all PENDING_PICKUP batches with GPS coords."""
    query = (
        sb.table("batches")
        .select(
            "batch_id,source_type,breed,wilaya,status,location_lat,location_lng,"
            "type_de_laine,sacs_count,estimated_sheep_count,created_at,action_timestamp,creator_id"
        )
        .eq("status", "PENDING_PICKUP")
        .order("created_at", desc=True)
    )
    if wilaya:
        query = query.ilike("wilaya", f"%{wilaya}%")
    rows = query.execute().data or []
    return _enrich_batches_with_contacts(sb, rows)


@router.get("/{batch_id}", response_model=BatchResponse)
async def get_batch(batch_id: str, sb: Client = Depends(get_supabase)):
    return _enrich_batch_with_contacts(sb, _require_batch(sb, batch_id))


# ── Create (C1 / C2 / C3) ───────────────────────────────────────────────────

@router.post("", response_model=BatchResponse, status_code=201)
async def create_batch(
    body: CreateBatchBody,
    sb: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
):
    """Source node creates a new collection request."""
    row = {
        "batch_id": body.batch_id,
        "source_type": body.source_type.value,
        "breed": body.breed.value,
        "wilaya": body.wilaya,
        "status": BatchStatus.PENDING_PICKUP.value,
        "creator_id": current_user["id"],
        "location_lat": body.location_lat,
        "location_lng": body.location_lng,
        "action_timestamp": body.action_timestamp,
        "annex_metadata": body.annex_metadata or {},
    }

    if body.type_de_laine:
        row["type_de_laine"] = body.type_de_laine.value

    # Source-specific fields stored in annex_metadata for traceability
    annex: dict = row.get("annex_metadata") or {}
    if body.estimated_sheep_count is not None:
        annex["estimated_sheep_count"] = body.estimated_sheep_count
    if body.skin_condition:
        annex["skin_condition"] = body.skin_condition
    if body.estimated_bags_count is not None:
        annex["estimated_bags_count"] = body.estimated_bags_count
    row["annex_metadata"] = annex

    row = {k: v for k, v in row.items() if v is not None}

    try:
        result = sb.table("batches").insert(row).execute()
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    return _enrich_batch_with_contacts(sb, result.data[0])


# ── Collector: collect & generate QR ────────────────────────────────────────

@router.post("/{batch_id}/collect", response_model=BatchResponse)
async def collect_batch(
    batch_id: str,
    body: CollectBody,
    sb: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
):
    """Collector weighs wool at source, sets price, transitions to COLLECTED_BY_BUYER."""
    existing = _require_batch(sb, batch_id)
    if existing["status"] != BatchStatus.PENDING_PICKUP.value:
        raise HTTPException(status_code=409, detail="Batch is not in PENDING_PICKUP state")

    update: dict = {
        "status": BatchStatus.COLLECTED_BY_BUYER.value,
        "collector_id": body.collector_id or current_user["id"],
        "purchase_price_dzd": body.purchase_price_dzd,
        "weight_raw_e1_kg": body.weight_raw_e1_kg,
        "proprete_score": body.proprete_score,
        "sacs_count": body.sacs_count,
        "action_timestamp": body.action_timestamp,
    }
    if body.type_de_laine:
        update["type_de_laine"] = body.type_de_laine.value

    update = {k: v for k, v in update.items() if v is not None}
    result = sb.table("batches").update(update).eq("batch_id", batch_id).execute()
    return _enrich_batch_with_contacts(sb, result.data[0])


# ── D1 Intake (scan QR, record received weight) ──────────────────────────────

@router.post("/{batch_id}/claim", response_model=BatchResponse)
async def claim_batch_for_collector(
    batch_id: str,
    sb: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
):
    """Assign a pending batch to the current collector."""
    existing = _require_batch(sb, batch_id)
    if existing.get("status") != BatchStatus.PENDING_PICKUP.value:
        raise HTTPException(status_code=409, detail="Batch is no longer pending")

    collector_id = str(current_user.get("id"))
    active_claim = (
        sb.table("batches")
        .select("batch_id")
        .eq("collector_id", collector_id)
        .eq("status", BatchStatus.COLLECTED_BY_BUYER.value)
        .limit(1)
        .execute()
    )
    if active_claim.data:
        raise HTTPException(
            status_code=409,
            detail="You already have an active load. Complete or cancel it first.",
        )

    now_iso = datetime.now(timezone.utc).isoformat()
    result = (
        sb.table("batches")
        .update(
            {
                "status": BatchStatus.COLLECTED_BY_BUYER.value,
                "collector_id": collector_id,
                "action_timestamp": now_iso,
            }
        )
        .eq("batch_id", batch_id)
        .eq("status", BatchStatus.PENDING_PICKUP.value)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=409, detail="Batch is no longer pending")
    return _enrich_batch_with_contacts(sb, result.data[0])


@router.post("/{batch_id}/cancel-claim", response_model=BatchResponse)
async def cancel_batch_claim_for_collector(
    batch_id: str,
    sb: Client = Depends(get_supabase),
    current_user: dict = Depends(get_current_user),
):
    """Cancel current collector assignment and return batch to pending."""
    existing = _require_batch(sb, batch_id)
    collector_id = str(current_user.get("id"))
    if existing.get("status") != BatchStatus.COLLECTED_BY_BUYER.value:
        raise HTTPException(status_code=409, detail="Batch is not an active load")
    if str(existing.get("collector_id") or "") != collector_id:
        raise HTTPException(status_code=403, detail="This load is not assigned to you")

    now_iso = datetime.now(timezone.utc).isoformat()
    result = (
        sb.table("batches")
        .update(
            {
                "status": BatchStatus.PENDING_PICKUP.value,
                "collector_id": None,
                "action_timestamp": now_iso,
            }
        )
        .eq("batch_id", batch_id)
        .eq("collector_id", collector_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=409, detail="Unable to cancel this load")
    return _enrich_batch_with_contacts(sb, result.data[0])


@router.patch("/{batch_id}/d1-intake", response_model=BatchResponse)
async def d1_intake(
    batch_id: str,
    body: D1IntakeBody,
    sb: Client = Depends(get_supabase),
):
    """D1 Worker scans QR and records actual weight at depot door."""
    existing = _require_batch(sb, batch_id)

    # weight_received_d1_kg stores the D1 actual received weight in annex_metadata
    # because the DB schema uses weight_raw_e1_kg as the canonical weight column.
    # We also update weight_raw_e1_kg only if it was not set by the collector.
    received = body.weight_received_d1_kg
    declared = existing.get("weight_raw_e1_kg") or 0

    annex = existing.get("annex_metadata") or {}
    annex["weight_received_d1_kg"] = received

    update: dict = {
        "status": BatchStatus.AT_D1_STOCKAGE.value,
        "annex_metadata": annex,
        "action_timestamp": body.action_timestamp,
    }
    if body.stockage_zone:
        update["stockage_zone"] = body.stockage_zone
    # If collector never set a raw weight, use the received weight as baseline.
    if not declared:
        update["weight_raw_e1_kg"] = received
        declared = received
    update = {k: v for k, v in update.items() if v is not None}

    # Weight discrepancy check
    if declared > 0:
        loss_pct = ((declared - received) / declared) * 100
        if loss_pct > 20:
            _fire_alert(
                sb,
                batch_id,
                "E1_PERTE_EN_ROUTE",
                "POINT_NOIR",
                (
                    f"Lot {batch_id}: collecteur a declare {declared}kg, "
                    f"D1 a recu {received}kg — "
                    f"{declared - received:.1f}kg manquants ({loss_pct:.0f}%)."
                ),
                "Verification du collecteur",
            )

    result = sb.table("batches").update(update).eq("batch_id", batch_id).execute()
    return _enrich_batch_with_contacts(sb, result.data[0])


# ── D1 Cleaning (hand clean / skin removal) ──────────────────────────────────

@router.patch("/{batch_id}/d1-clean", response_model=BatchResponse)
async def d1_clean(
    batch_id: str,
    body: D1CleanBody,
    sb: Client = Depends(get_supabase),
):
    """D1 Worker enters post-hand-cleaning weight. Backend checks yield thresholds."""
    existing = _require_batch(sb, batch_id)

    existing_annex = existing.get("annex_metadata") or {}
    if body.waste_removed_kg is not None:
        existing_annex["waste_removed_kg"] = body.waste_removed_kg
    if body.skin_removed_kg is not None:
        existing_annex["skin_removed_kg"] = body.skin_removed_kg

    update: dict = {
        "weight_after_handclean_kg": body.weight_after_handclean_kg,
        "taux_matiere_vegetale_percent": body.taux_matiere_vegetale_percent,
        "temperature_tas_celsius": body.temperature_tas_celsius,
        "annex_metadata": existing_annex,
        "action_timestamp": body.action_timestamp,
    }
    if body.classification:
        update["classification"] = body.classification.value
    update = {k: v for k, v in update.items() if v is not None}

    # Yield alert — use received weight from annex if available, else declared raw
    annex_d1 = existing.get("annex_metadata") or {}
    raw = annex_d1.get("weight_received_d1_kg") or existing.get("weight_raw_e1_kg") or 0
    source = existing.get("source_type", "C1")
    if raw > 0:
        yield_ratio = body.weight_after_handclean_kg / raw
        min_yield = 0.35 if source == "C2" else 0.55
        if yield_ratio < min_yield:
            _fire_alert(
                sb,
                batch_id,
                "A1_RENDEMENT",
                "POINT_ROUGE",
                (
                    f"Lot {batch_id} ({source}): rendement nettoyage {yield_ratio * 100:.1f}% "
                    f"(seuil minimum {min_yield * 100:.0f}%)."
                ),
                "Verifier D1",
            )

    # Incoherent weight — after cleaning heavier than before
    if body.weight_after_handclean_kg > raw > 0:
        _fire_alert(
            sb,
            batch_id,
            "E2_INCOHERENT_POIDS",
            "POINT_NOIR",
            f"Lot {batch_id}: poids apres nettoyage ({body.weight_after_handclean_kg}kg) > poids recu ({raw}kg).",
            "Recontrole pesee",
        )

    # Auto-combustion risk
    if body.temperature_tas_celsius is not None and body.temperature_tas_celsius >= 45:
        _fire_alert(
            sb,
            batch_id,
            "ALERTE_AUTO_COMBUSTION",
            "POINT_ROUGE",
            f"Lot {batch_id}: temperature tas {body.temperature_tas_celsius}C — risque d'incendie.",
            "Isoler le lot",
        )

    # High vegetable matter
    if body.taux_matiere_vegetale_percent is not None and body.taux_matiere_vegetale_percent > 5:
        _fire_alert(
            sb,
            batch_id,
            "ALERTE_MATIERES_VEGETALES",
            "POINT_JAUNE",
            f"Lot {batch_id}: taux paille {body.taux_matiere_vegetale_percent:.1f}% > 5% — Classe B recommandee.",
            "Rediriger Classe B",
        )

    result = sb.table("batches").update(update).eq("batch_id", batch_id).execute()
    return _enrich_batch_with_contacts(sb, result.data[0])


# ── D2 Washing ───────────────────────────────────────────────────────────────

@router.patch("/{batch_id}/d2-wash", response_model=BatchResponse)
async def d2_wash(
    batch_id: str,
    body: D2WashBody,
    sb: Client = Depends(get_supabase),
):
    """Washer logs wash parameters and routes to D3 (textiles) or D4 (engrais)."""
    existing = _require_batch(sb, batch_id)

    if body.final_destination not in ("D3_TEXTILES", "D4_ENGRAIS"):
        raise HTTPException(
            status_code=422,
            detail="final_destination must be D3_TEXTILES or D4_ENGRAIS",
        )

    # water_temp_celsius and detergent_type are not DB columns — stored in annex_metadata.
    annex_d2 = existing.get("annex_metadata") or {}
    if body.water_temp_celsius is not None:
        annex_d2["water_temp_celsius"] = body.water_temp_celsius
    if body.detergent_type:
        annex_d2["detergent_type"] = body.detergent_type

    update: dict = {
        "status": BatchStatus.AT_D2_LAVAGE.value,
        "weight_clean_d2_kg": body.weight_clean_d2_kg,
        "humidite_sortie_percent": body.humidite_sortie_percent,
        "ph_laine": body.ph_laine,
        "final_destination": body.final_destination,
        "annex_metadata": annex_d2,
        "action_timestamp": body.action_timestamp,
    }
    update = {k: v for k, v in update.items() if v is not None}

    # Yield vs source threshold
    pre_clean = existing.get("weight_after_handclean_kg") or 0
    source = existing.get("source_type", "C1")
    if pre_clean > 0:
        yield_pct = (body.weight_clean_d2_kg / pre_clean) * 100
        # Washing always removes more — flag only extreme cases
        if yield_pct < 30:
            _fire_alert(
                sb,
                batch_id,
                "ALERTE_RENDEMENT_LAVAGE",
                "POINT_JAUNE",
                f"Lot {batch_id}: rendement lavage {yield_pct:.1f}% tres bas.",
                "Verification D2",
            )

    result = sb.table("batches").update(update).eq("batch_id", batch_id).execute()
    return _enrich_batch_with_contacts(sb, result.data[0])


# ── Transformer (D3 / D4 factory) ───────────────────────────────────────────
@router.patch("/{batch_id}/transform-intake", response_model=BatchResponse)
async def transform_intake(
    batch_id: str,
    body: TransformIntakeBody,
    sb: Client = Depends(get_supabase),
):
    """Transformer records received weight and checks against washer's declared weight."""
    existing = _require_batch(sb, batch_id)
    
    received = body.weight_received_factory_kg
    declared = existing.get("weight_clean_d2_kg") or 0
    
    annex = existing.get("annex_metadata") or {}
    annex["weight_received_factory_kg"] = received
    
    update: dict = {
        "status": BatchStatus.IN_TRANSFORMATION.value,
        "annex_metadata": annex,
        "action_timestamp": body.action_timestamp,
    }
    update = {k: v for k, v in update.items() if v is not None}
    
    # Discrepancy check
    if declared > 0:
        diff = abs(declared - received)
        if diff > 100: # Arbitrary threshold, can be percentage based
            _fire_alert(
                sb,
                batch_id,
                "FACTORY_INTAKE_DISCREPANCY",
                "POINT_JAUNE",
                f"Lot {batch_id}: Laveur a declare {declared}kg, Factory a recu {received}kg.",
                "Verification du transport",
            )
            
    result = sb.table("batches").update(update).eq("batch_id", batch_id).execute()
    return result.data[0]


@router.patch("/{batch_id}/transform", response_model=BatchResponse)
async def transform(
    batch_id: str,
    body: TransformBody,
    sb: Client = Depends(get_supabase),
):
    """Factory seals the batch with final product metrics and marks it ready for sale."""
    # product_type, total_units_produced and total_finished_weight_kg not in DB schema — go in annex.
    existing_batch = _require_batch(sb, batch_id)
    annex_tf = existing_batch.get("annex_metadata") or {}
    annex_tf["product_type"] = body.product_type
    if body.total_units_produced is not None:
        annex_tf["total_units_produced"] = body.total_units_produced
    if body.total_finished_weight_kg is not None:
        annex_tf["total_finished_weight_kg"] = body.total_finished_weight_kg

    update: dict = {
        "status": BatchStatus.READY_FOR_SALE.value,
        "fiber_length_mm": body.fiber_length_mm,
        "finesse_micron": body.finesse_micron,
        "humidity_percent": body.humidity_percent,
        "annex_metadata": annex_tf,
        "is_ready_for_sale": True,
        "action_timestamp": body.action_timestamp,
    }
    update = {k: v for k, v in update.items() if v is not None}

    result = sb.table("batches").update(update).eq("batch_id", batch_id).execute()
    return _enrich_batch_with_contacts(sb, result.data[0])
