from fastapi import APIRouter, Depends, HTTPException
from supabase import Client
from uuid import uuid4

from app.deps import get_supabase
from app.schemas import SyncPayload, SyncResult

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("", response_model=SyncResult)
async def bulk_sync(payload: SyncPayload, sb: Client = Depends(get_supabase)):
    """
    Bulk sync endpoint for offline mobile app data.
    Accepts an array of batch operations cached on the device.
    Uses upsert to handle duplicate batch_ids from re-syncs.
    """
    synced = 0
    failed = 0
    errors: list[str] = []

    for item in payload.items:
        row = {
            "batch_id": item.batch_id,
            "source_type": item.source_type,
            "breed": item.breed.value,
            "wilaya": item.wilaya,
            "status": item.status.value,
            "creator_phone": item.creator_phone,
            "collector_phone": item.collector_phone,
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
            "location_lat": item.location_lat,
            "location_lng": item.location_lng,
            "action_timestamp": item.action_timestamp,
            "annex_metadata": item.annex_metadata,
        }

        # Strip None values
        row = {k: v for k, v in row.items() if v is not None}

        try:
            sb.table("batches").upsert(row, on_conflict="batch_id").execute()
            synced += 1

            # Auto-generate alerts for suspicious data
            raw = item.weight_raw_e1_kg or 0
            after = item.weight_after_handclean_kg or 0
            if raw > 0 and after > 0:
                loss = ((raw - after) / raw) * 100
                if loss > 20:
                    sb.table("alerts").upsert(
                        {
                            "id": str(uuid4()),
                            "batch_id": item.batch_id,
                            "alert_type": "E1_PERTE_EN_ROUTE",
                            "severity": "POINT_NOIR",
                            "is_resolved": False,
                            "description": (
                                f"Batch {item.batch_id}. "
                                f"Declared {raw}kg. Received {after}kg. "
                                f"{raw - after:.0f}kg missing."
                            ),
                        },
                        on_conflict="id",
                    ).execute()

            if item.temperature_tas_celsius is not None and item.temperature_tas_celsius >= 45:
                sb.table("alerts").upsert(
                    {
                        "id": str(uuid4()),
                        "batch_id": item.batch_id,
                        "alert_type": "ALERTE_AUTO_COMBUSTION",
                        "severity": "POINT_ROUGE",
                        "is_resolved": False,
                        "description": (
                            f"Lot {item.batch_id} (Depot D1). "
                            f"Temperature du tas critique ({item.temperature_tas_celsius}C). "
                            "Risque d'incendie ou pourriture."
                        ),
                        "action": "Isoler le lot",
                    },
                    on_conflict="id",
                ).execute()

            if item.taux_matiere_vegetale_percent is not None and item.taux_matiere_vegetale_percent > 5:
                sb.table("alerts").upsert(
                    {
                        "id": str(uuid4()),
                        "batch_id": item.batch_id,
                        "alert_type": "ALERTE_MATIERES_VEGETALES",
                        "severity": "POINT_JAUNE",
                        "is_resolved": False,
                        "description": (
                            f"Lot {item.batch_id}. "
                            "Taux de paille > 5%. Action auto: Redirige vers Classe B (Engrais)."
                        ),
                        "action": "Rediriger Classe B",
                    },
                    on_conflict="id",
                ).execute()

            raw_for_yield = item.weight_raw_e1_kg or 0
            clean_for_yield = item.weight_clean_d2_kg or 0
            if raw_for_yield > 0 and clean_for_yield > 0:
                yield_percent = (clean_for_yield / raw_for_yield) * 100
                min_expected = 55 if item.source_type == "C1" else 35 if item.source_type == "C2" else None
                if min_expected is not None and yield_percent < min_expected:
                    sb.table("alerts").upsert(
                        {
                            "id": str(uuid4()),
                            "batch_id": item.batch_id,
                            "alert_type": "ALERTE_RENDEMENT_INTELLIGENT",
                            "severity": "POINT_ROUGE",
                            "is_resolved": False,
                            "description": (
                                f"Lot {item.batch_id} ({item.source_type}). "
                                f"Rendement actuel: {yield_percent:.0f}%. "
                                f"Anomalie: Le rendement doit etre > {min_expected}%."
                            ),
                            "action": "Controle fournisseur",
                        },
                        on_conflict="id",
                    ).execute()

        except Exception as exc:
            failed += 1
            errors.append(f"{item.batch_id}: {exc}")

    return SyncResult(synced=synced, failed=failed, errors=errors)
