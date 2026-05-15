from fastapi import APIRouter, Depends
from supabase import Client

from app.deps import get_supabase
from app.schemas import DashboardKPIs, BreedDistribution, QualitySplit

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/kpis", response_model=DashboardKPIs)
async def get_kpis(sb: Client = Depends(get_supabase)):
    """Aggregated KPI metrics for the dashboard home page."""
    result = sb.table("batches").select("*").execute()
    batches = result.data or []

    alert_result = sb.table("alerts").select("id, is_resolved").execute()
    alerts = alert_result.data or []

    volume_declared = sum(b.get("weight_raw_e1_kg") or 0 for b in batches)
    volume_received = sum(b.get("weight_after_handclean_kg") or 0 for b in batches)

    yields = []
    for b in batches:
        clean = b.get("weight_clean_d2_kg") or 0
        pre = b.get("weight_after_handclean_kg") or 0
        if clean > 0 and pre > 0:
            yields.append((clean / pre) * 100)

    avg_yield = round(sum(yields) / len(yields), 1) if yields else 0.0
    loss = round(((volume_declared - volume_received) / volume_declared) * 100, 1) if volume_declared > 0 else 0.0
    active_alerts = sum(1 for a in alerts if not a.get("is_resolved", False))

    status_counts: dict[str, int] = {}
    for b in batches:
        s = b.get("status", "UNKNOWN")
        status_counts[s] = status_counts.get(s, 0) + 1

    return DashboardKPIs(
        volume_declared_kg=volume_declared,
        volume_received_kg=volume_received,
        loss_percent=loss,
        average_yield=avg_yield,
        active_alerts=active_alerts,
        total_batches=len(batches),
        batches_by_status=status_counts,
    )


@router.get("/breed-distribution", response_model=list[BreedDistribution])
async def breed_distribution(sb: Client = Depends(get_supabase)):
    """Breed breakdown percentages across all batches."""
    result = sb.table("batches").select("breed").execute()
    batches = result.data or []

    counts: dict[str, int] = {}
    for b in batches:
        breed = b.get("breed", "UNKNOWN")
        counts[breed] = counts.get(breed, 0) + 1

    total = len(batches) or 1
    return [
        BreedDistribution(breed=breed, count=count, percentage=round((count / total) * 100, 1))
        for breed, count in sorted(counts.items(), key=lambda x: -x[1])
    ]


@router.get("/quality-split", response_model=QualitySplit)
async def quality_split(sb: Client = Depends(get_supabase)):
    """D3 vs D4 destination split for transformed/ready batches."""
    result = (
        sb.table("batches")
        .select("final_destination")
        .in_("status", ["IN_TRANSFORMATION", "READY_FOR_SALE"])
        .execute()
    )
    batches = result.data or []

    d3 = sum(1 for b in batches if b.get("final_destination") == "D3")
    d4 = sum(1 for b in batches if b.get("final_destination") == "D4")
    total = d3 + d4 or 1

    return QualitySplit(
        d3_count=d3,
        d4_count=d4,
        d3_percent=round((d3 / total) * 100, 1),
        d4_percent=round((d4 / total) * 100, 1),
    )
