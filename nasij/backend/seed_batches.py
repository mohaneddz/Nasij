"""
Seed script — inserts sample batches at every pipeline stage.
Run from the nasij/backend directory:
    python seed_batches.py
"""
import os
from datetime import datetime, timezone
from supabase import create_client

# Load env
from dotenv import load_dotenv
load_dotenv(".env")

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_SERVICE_ROLE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]

sb = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

now = datetime.now(timezone.utc).isoformat()

batches = [
    # ── Stage 1: Pending Pickup (visible to Collector)
    {
        "batch_id": "SEED-2026-001",
        "source_type": "C1",
        "breed": "OULED_DJELLAL",
        "wilaya": "Tébessa",
        "status": "PENDING_PICKUP",
        "location_lat": 35.4,
        "location_lng": 8.12,
        "annex_metadata": {"estimated_sheep_count": 45},
        "synced_at": now,
    },
    {
        "batch_id": "SEED-2026-002",
        "source_type": "C2",
        "breed": "REMBI",
        "wilaya": "Sétif",
        "status": "PENDING_PICKUP",
        "location_lat": 36.19,
        "location_lng": 5.41,
        "annex_metadata": {"skin_condition": "Fresh"},
        "synced_at": now,
    },
    # ── Stage 2: Collected by Buyer (Collector scanned, waiting D1)
    {
        "batch_id": "SEED-2026-003",
        "source_type": "C1",
        "breed": "EL_HAMRA",
        "wilaya": "Batna",
        "status": "COLLECTED_BY_BUYER",
        "weight_raw_e1_kg": 120.5,
        "purchase_price_dzd": 48000,
        "sacs_count": 4,
        "proprete_score": 3,
        "type_de_laine": "TOISON_ENTIERE",
        "synced_at": now,
    },
    # ── Stage 3: At D1 Stockage (Depot received, not yet cleaned)
    {
        "batch_id": "SEED-2026-004",
        "source_type": "C1",
        "breed": "OULED_DJELLAL",
        "wilaya": "Khenchela",
        "status": "AT_D1_STOCKAGE",
        "weight_raw_e1_kg": 98.0,
        "purchase_price_dzd": 39200,
        "annex_metadata": {"weight_received_d1_kg": 95.0},
        "synced_at": now,
    },
    {
        "batch_id": "SEED-2026-005",
        "source_type": "C2",
        "breed": "REMBI",
        "wilaya": "Tébessa",
        "status": "AT_D1_STOCKAGE",
        "weight_raw_e1_kg": 210.0,
        "purchase_price_dzd": 84000,
        "annex_metadata": {"weight_received_d1_kg": 205.0},
        "synced_at": now,
    },
    # ── Stage 3b: At D1 Stockage, cleaned (Depot Inventory ready to ship)
    {
        "batch_id": "SEED-2026-006",
        "source_type": "C1",
        "breed": "MIXTE",
        "wilaya": "Biskra",
        "status": "AT_D1_STOCKAGE",
        "weight_raw_e1_kg": 150.0,
        "weight_after_handclean_kg": 138.5,
        "taux_matiere_vegetale_percent": 2.1,
        "annex_metadata": {
            "weight_received_d1_kg": 148.0,
            "waste_removed_kg": 8.0,
            "skin_removed_kg": 3.5,
        },
        "synced_at": now,
    },
    # ── Stage 4: At D2 Lavage (arrived at Washer, not yet washed)
    {
        "batch_id": "SEED-2026-007",
        "source_type": "C1",
        "breed": "OULED_DJELLAL",
        "wilaya": "Sétif",
        "status": "AT_D2_LAVAGE",
        "weight_raw_e1_kg": 105.0,
        "weight_after_handclean_kg": 96.0,
        "annex_metadata": {"washer_received_at": now},
        "synced_at": now,
    },
    {
        "batch_id": "SEED-2026-008",
        "source_type": "C2",
        "breed": "EL_HAMRA",
        "wilaya": "Batna",
        "status": "AT_D2_LAVAGE",
        "weight_raw_e1_kg": 190.0,
        "weight_after_handclean_kg": 175.0,
        "annex_metadata": {"washer_received_at": now},
        "synced_at": now,
    },
    # ── Stage 4b: At D2 Lavage, washed and classified (Finished Bales at Washer)
    {
        "batch_id": "SEED-2026-009",
        "source_type": "C1",
        "breed": "OULED_DJELLAL",
        "wilaya": "Tébessa",
        "status": "AT_D2_LAVAGE",
        "weight_raw_e1_kg": 130.0,
        "weight_after_handclean_kg": 122.0,
        "weight_clean_d2_kg": 88.5,
        "final_destination": "D3_TEXTILES",
        "humidite_sortie_percent": 14.2,
        "ph_laine": 6.8,
        "annex_metadata": {"washer_received_at": now, "pre_wash_weight_kg": 115.0},
        "synced_at": now,
    },
    {
        "batch_id": "SEED-2026-010",
        "source_type": "C2",
        "breed": "REMBI",
        "wilaya": "Biskra",
        "status": "AT_D2_LAVAGE",
        "weight_raw_e1_kg": 200.0,
        "weight_after_handclean_kg": 188.0,
        "weight_clean_d2_kg": 142.0,
        "final_destination": "D4_ENGRAIS",
        "humidite_sortie_percent": 18.0,
        "ph_laine": 7.2,
        "annex_metadata": {"washer_received_at": now},
        "synced_at": now,
    },
    # ── Stage 5: In Transformation (Transformer production queue)
    {
        "batch_id": "SEED-2026-011",
        "source_type": "C1",
        "breed": "MIXTE",
        "wilaya": "Sétif",
        "status": "IN_TRANSFORMATION",
        "weight_raw_e1_kg": 160.0,
        "weight_after_handclean_kg": 148.0,
        "weight_clean_d2_kg": 110.0,
        "final_destination": "D3_TEXTILES",
        "annex_metadata": {"weight_received_factory_kg": 108.5},
        "synced_at": now,
    },
    # ── Stage 6: Ready for Sale (Finished goods at Transformer)
    {
        "batch_id": "SEED-2026-012",
        "source_type": "C1",
        "breed": "OULED_DJELLAL",
        "wilaya": "Batna",
        "status": "READY_FOR_SALE",
        "weight_raw_e1_kg": 140.0,
        "weight_after_handclean_kg": 130.0,
        "weight_clean_d2_kg": 95.0,
        "final_destination": "D3_TEXTILES",
        "fiber_length_mm": 82.5,
        "finesse_micron": 28.3,
        "humidity_percent": 12.5,
        "is_ready_for_sale": True,
        "annex_metadata": {"product_type": "Insulation Panels", "total_units_produced": 24},
        "synced_at": now,
    },
]

print(f"Seeding {len(batches)} batches...")

for batch in batches:
    try:
        result = sb.table("batches").upsert(batch, on_conflict="batch_id").execute()
        print(f"  OK  {batch['batch_id']} ({batch['status']})")
    except Exception as e:
        print(f"  FAIL  {batch['batch_id']} -- {e}")

print("\nDone! Run the Flutter app and check each employee screen.")
