"""
Database seeder — inserts 20+ realistic batches and alerts into Supabase.
Run: cd nfn-backend && python -m app.seed
"""
import os
import sys
import uuid
from pathlib import Path
from dotenv import load_dotenv

BACKEND_DIR = Path(__file__).resolve().parents[1]
load_dotenv(BACKEND_DIR / ".env", override=True)

from supabase import create_client


def main():
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

    if not url or not key:
        print("[SEED] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")
        sys.exit(1)

    sb = create_client(url, key)
    print(f"[SEED] Connected to {url}")

    # Clear existing data
    print("[SEED] Clearing existing data...")
    sb.table("alerts").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
    sb.table("batches").delete().neq("batch_id", "NEVER_MATCH").execute()
    sb.table("users").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()

    # Pre-add Admin User
    admin_phone = "0770112233" # Admin identity
    admin_email = f"{admin_phone}@nfn.local"
    admin_password = "admin" # Simple password for demo
    
    print(f"[SEED] Ensuring Admin user: {admin_email}")
    try:
        # Check if auth user exists
        auth_users = sb.auth.admin.list_users()
        existing_auth = next((u for u in auth_users if u.email == admin_email), None)
        
        if not existing_auth:
            new_auth = sb.auth.admin.create_user({
                "email": admin_email,
                "password": admin_password,
                "user_metadata": {"phone": admin_phone, "sector": "MANAGER", "full_name": "NFN Admin"},
                "email_confirm": True
            })
            admin_uuid = new_auth.user.id
            print(f"[SEED] Created new Auth user: {admin_uuid}")
        else:
            admin_uuid = existing_auth.id
            print(f"[SEED] Admin Auth user already exists: {admin_uuid}")

    except Exception as e:
        print(f"[SEED] Warning during admin auth creation: {e}")
        admin_uuid = str(uuid.uuid4())

    def ensure_user(users_store, user_index, phone_number, sector, wilaya):
        if not phone_number:
            return None
        if phone_number in user_index:
            return user_index[phone_number]
        user_id = str(uuid.uuid4())
        sector_value = sector or "WORKER"
        full_name = f"{sector_value.replace('_', ' ').title()} {phone_number[-4:]}"
        users_store.append({
            "id": user_id,
            "phone_number": phone_number,
            "sector": sector_value,
            "role": sector_value,
            "full_name": full_name,
            "wilaya": wilaya,
        })
        user_index[phone_number] = user_id
        return user_id

    # Add Admin to users table
    db_users = [{
        "id": admin_uuid,
        "phone_number": admin_phone,
        "sector": "MANAGER",
        "role": "MANAGER",
        "full_name": "NFN Admin (Control Tower)",
        "wilaya": "Alger",
    }]
    user_index = {admin_phone: admin_uuid}

    # ── Batches ─────────────────────────────────────
    raw_batches = [
        # PENDING_PICKUP (5) — waiting at farms
        {
            "batch_id": "NFN-899",
            "source_type": "C1", "breed": "OULED_DJELLAL", "wilaya": "Djelfa",
            "status": "PENDING_PICKUP",
            "purchase_price_dzd": 15000, "weight_raw_e1_kg": 520,
            "location_lat": 34.69, "location_lng": 3.24,
            "creator_phone": "0555001122",
            "action_timestamp": "2026-04-22T10:00:00Z",
        },
        {
            "batch_id": "NFN-901",
            "source_type": "C1", "breed": "REMBI", "wilaya": "Laghouat",
            "status": "PENDING_PICKUP",
            "purchase_price_dzd": 12800, "weight_raw_e1_kg": 380,
            "location_lat": 33.80, "location_lng": 2.88,
            "creator_phone": "0555002233",
            "action_timestamp": "2026-04-22T11:30:00Z",
        },
        {
            "batch_id": "NFN-902",
            "source_type": "C3", "breed": "EL_HAMRA", "wilaya": "Biskra",
            "status": "PENDING_PICKUP",
            "purchase_price_dzd": 19500, "weight_raw_e1_kg": 610,
            "location_lat": 34.85, "location_lng": 5.73,
            "creator_phone": "0555003344",
            "action_timestamp": "2026-04-22T14:00:00Z",
        },
        {
            "batch_id": "NFN-903",
            "source_type": "C1", "breed": "BARBAR", "wilaya": "Setif",
            "status": "PENDING_PICKUP",
            "purchase_price_dzd": 11200, "weight_raw_e1_kg": 290,
            "location_lat": 36.19, "location_lng": 5.41,
            "creator_phone": "0555004455",
            "action_timestamp": "2026-04-23T08:00:00Z",
        },
        {
            "batch_id": "NFN-904",
            "source_type": "C1", "breed": "TEZEGZAWET", "wilaya": "Tizi Ouzou",
            "status": "PENDING_PICKUP",
            "purchase_price_dzd": 9800, "weight_raw_e1_kg": 210,
            "location_lat": 36.71, "location_lng": 4.05,
            "creator_phone": "0555005566",
            "action_timestamp": "2026-04-23T09:15:00Z",
        },

        # COLLECTED_BY_BUYER (3) — trucks in transit
        {
            "batch_id": "NFN-900",
            "source_type": "C2", "breed": "REMBI", "wilaya": "Tiaret",
            "status": "COLLECTED_BY_BUYER",
            "purchase_price_dzd": 17200, "weight_raw_e1_kg": 430,
            "location_lat": 35.32, "location_lng": 1.63,
            "creator_phone": "0555010011",
            "collector_phone": "0555123456",
            "action_timestamp": "2026-04-23T09:12:00Z",
        },
        {
            "batch_id": "NFN-905",
            "source_type": "C1", "breed": "OULED_DJELLAL", "wilaya": "M'Sila",
            "status": "COLLECTED_BY_BUYER",
            "purchase_price_dzd": 14300, "weight_raw_e1_kg": 470,
            "location_lat": 35.70, "location_lng": 4.54,
            "creator_phone": "0555011122",
            "collector_phone": "0555789012",
            "action_timestamp": "2026-04-23T10:30:00Z",
        },
        {
            "batch_id": "NFN-906",
            "source_type": "C3", "breed": "MIXTE", "wilaya": "Batna",
            "status": "COLLECTED_BY_BUYER",
            "purchase_price_dzd": 21000, "weight_raw_e1_kg": 550,
            "location_lat": 35.55, "location_lng": 6.17,
            "creator_phone": "0555012233",
            "collector_phone": "0555345678",
            "action_timestamp": "2026-04-23T11:00:00Z",
        },

        # AT_D1_STOCKAGE (4) — in warehouse
        {
            "batch_id": "NFN-102",
            "source_type": "C3", "breed": "EL_HAMRA", "wilaya": "Batna",
            "status": "AT_D1_STOCKAGE",
            "purchase_price_dzd": 23000,
            "weight_raw_e1_kg": 500, "weight_after_handclean_kg": 400,
            "stockage_zone": "EL_HAMRA",
            "location_lat": 35.55, "location_lng": 6.17,
            "creator_phone": "0555013344",
            "action_timestamp": "2026-04-21T08:42:00Z",
        },
        {
            "batch_id": "NFN-907",
            "source_type": "C1", "breed": "OULED_DJELLAL", "wilaya": "Djelfa",
            "status": "AT_D1_STOCKAGE",
            "purchase_price_dzd": 16500,
            "weight_raw_e1_kg": 480, "weight_after_handclean_kg": 460,
            "stockage_zone": "OULED_DJELLAL",
            "location_lat": 34.69, "location_lng": 3.24,
            "creator_phone": "0555014455",
            "action_timestamp": "2026-04-20T15:00:00Z",
        },
        {
            "batch_id": "NFN-908",
            "source_type": "C2", "breed": "REMBI", "wilaya": "Tiaret",
            "status": "AT_D1_STOCKAGE",
            "purchase_price_dzd": 18200,
            "weight_raw_e1_kg": 350, "weight_after_handclean_kg": 310,
            "stockage_zone": "REMBI",
            "location_lat": 35.32, "location_lng": 1.63,
            "creator_phone": "0555015566",
            "action_timestamp": "2026-04-20T16:30:00Z",
        },
        {
            "batch_id": "NFN-909",
            "source_type": "C1", "breed": "BARBAR", "wilaya": "Setif",
            "status": "AT_D1_STOCKAGE",
            "purchase_price_dzd": 13800,
            "weight_raw_e1_kg": 410, "weight_after_handclean_kg": 395,
            "stockage_zone": "BARBAR",
            "location_lat": 36.19, "location_lng": 5.41,
            "creator_phone": "0555016677",
            "action_timestamp": "2026-04-20T09:00:00Z",
        },

        # AT_D2_LAVAGE (3) — washing
        {
            "batch_id": "NFN-304",
            "source_type": "C2", "breed": "MIXTE", "wilaya": "M'Sila",
            "status": "AT_D2_LAVAGE",
            "purchase_price_dzd": 18500,
            "weight_raw_e1_kg": 200, "weight_after_handclean_kg": 80,
            "weight_clean_d2_kg": 75,
            "stockage_zone": "EL_HAMRA",
            "location_lat": 35.70, "location_lng": 4.54,
            "creator_phone": "0555017788",
            "collector_phone": "0555900304",
            "action_timestamp": "2026-04-20T14:10:00Z",
        },
        {
            "batch_id": "NFN-910",
            "source_type": "C1", "breed": "OULED_DJELLAL", "wilaya": "Djelfa",
            "status": "AT_D2_LAVAGE",
            "purchase_price_dzd": 20000,
            "weight_raw_e1_kg": 590, "weight_after_handclean_kg": 570,
            "weight_clean_d2_kg": 250,
            "stockage_zone": "OULED_DJELLAL",
            "location_lat": 34.82, "location_lng": 3.18,
            "creator_phone": "0555018899",
            "action_timestamp": "2026-04-19T13:00:00Z",
        },
        {
            "batch_id": "NFN-911",
            "source_type": "C3", "breed": "REMBI", "wilaya": "Laghouat",
            "status": "AT_D2_LAVAGE",
            "purchase_price_dzd": 15600,
            "weight_raw_e1_kg": 440, "weight_after_handclean_kg": 420,
            "weight_clean_d2_kg": 195,
            "stockage_zone": "REMBI",
            "location_lat": 33.80, "location_lng": 2.88,
            "creator_phone": "0555019900",
            "action_timestamp": "2026-04-19T10:30:00Z",
        },

        # IN_TRANSFORMATION (2)
        {
            "batch_id": "NFN-512",
            "source_type": "C1", "breed": "REMBI", "wilaya": "Djelfa",
            "status": "IN_TRANSFORMATION",
            "purchase_price_dzd": 19800,
            "weight_raw_e1_kg": 640, "weight_after_handclean_kg": 598,
            "weight_clean_d2_kg": 270,
            "fiber_length_mm": 84, "finesse_micron": 22.5, "humidity_percent": 9.2,
            "final_destination": "D3",
            "stockage_zone": "REMBI",
            "location_lat": 34.82, "location_lng": 3.18,
            "creator_phone": "0555020011",
            "action_timestamp": "2026-04-19T11:20:00Z",
        },
        {
            "batch_id": "NFN-912",
            "source_type": "C2", "breed": "EL_HAMRA", "wilaya": "Biskra",
            "status": "IN_TRANSFORMATION",
            "purchase_price_dzd": 22500,
            "weight_raw_e1_kg": 510, "weight_after_handclean_kg": 480,
            "weight_clean_d2_kg": 210,
            "fiber_length_mm": 72, "finesse_micron": 26.8, "humidity_percent": 11.0,
            "final_destination": "D4",
            "stockage_zone": "EL_HAMRA",
            "location_lat": 34.85, "location_lng": 5.73,
            "creator_phone": "0555021122",
            "action_timestamp": "2026-04-18T15:00:00Z",
        },

        # READY_FOR_SALE (3) — certified
        {
            "batch_id": "NFN-710",
            "source_type": "C1", "breed": "OULED_DJELLAL", "wilaya": "Djelfa",
            "status": "READY_FOR_SALE",
            "purchase_price_dzd": 21000,
            "weight_raw_e1_kg": 560, "weight_after_handclean_kg": 548,
            "weight_clean_d2_kg": 242,
            "fiber_length_mm": 88, "finesse_micron": 21.1, "humidity_percent": 8.8,
            "final_destination": "D3",
            "stockage_zone": "OULED_DJELLAL",
            "location_lat": 34.90, "location_lng": 3.10,
            "creator_phone": "0555022233",
            "action_timestamp": "2026-04-18T08:00:00Z",
        },
        {
            "batch_id": "NFN-711",
            "source_type": "C3", "breed": "BARBAR", "wilaya": "Tiaret",
            "status": "READY_FOR_SALE",
            "purchase_price_dzd": 16000,
            "weight_raw_e1_kg": 510, "weight_after_handclean_kg": 500,
            "weight_clean_d2_kg": 180,
            "fiber_length_mm": 62, "finesse_micron": 29.2, "humidity_percent": 10.5,
            "final_destination": "D4",
            "stockage_zone": "BARBAR",
            "location_lat": 35.40, "location_lng": 1.29,
            "creator_phone": "0555023344",
            "action_timestamp": "2026-04-17T13:30:00Z",
        },
        {
            "batch_id": "NFN-713",
            "source_type": "C1", "breed": "REMBI", "wilaya": "Laghouat",
            "status": "READY_FOR_SALE",
            "purchase_price_dzd": 17500,
            "weight_raw_e1_kg": 520, "weight_after_handclean_kg": 510,
            "weight_clean_d2_kg": 230,
            "fiber_length_mm": 78, "finesse_micron": 23.5, "humidity_percent": 9.8,
            "final_destination": "D3",
            "stockage_zone": "REMBI",
            "location_lat": 33.80, "location_lng": 2.88,
            "creator_phone": "0555024455",
            "action_timestamp": "2026-04-16T11:00:00Z",
        },
    ]

    batches = raw_batches

    batches.extend([
        {
            "batch_id": "NFN-202",
            "source_type": "C1", "breed": "OULED_DJELLAL", "wilaya": "Djelfa",
            "status": "AT_D2_LAVAGE",
            "purchase_price_dzd": 15400,
            "weight_raw_e1_kg": 500, "weight_after_handclean_kg": 460,
            "weight_clean_d2_kg": 200, "yield_percentage": 40,
            "stockage_zone": "OULED_DJELLAL",
            "location_lat": 34.78, "location_lng": 3.08,
            "creator_phone": "0555025566",
            "collector_phone": "0555900202",
            "action_timestamp": "2026-04-20T12:00:00Z",
        },
        {
            "batch_id": "NFN-405",
            "source_type": "C3", "breed": "BARBAR", "wilaya": "Setif",
            "status": "AT_D1_STOCKAGE",
            "purchase_price_dzd": 13600,
            "weight_raw_e1_kg": 310, "weight_after_handclean_kg": 280,
            "stockage_zone": "BARBAR",
            "final_destination": "D4",
            "location_lat": 36.19, "location_lng": 5.41,
            "creator_phone": "0555026677",
            "collector_phone": "0555900405",
            "action_timestamp": "2026-04-20T10:00:00Z",
        },
    ])

    annex_defaults = {
        "C1": {
            "type_de_laine": "TOISON_ENTIERE",
            "proprete_score": 4,
            "sacs_count": 18,
            "classification": "CLASSE_A_PROPRE",
            "temperature_tas_celsius": 34,
            "taux_matiere_vegetale_percent": 2,
            "humidite_sortie_percent": 12.5,
            "ph_laine": 7.1,
            "yield_percentage": 62,
        },
        "C2": {
            "type_de_laine": "PELADE_CHIMIQUE",
            "proprete_score": 4,
            "sacs_count": 11,
            "classification": "CLASSE_B_SOUILLEE",
            "temperature_tas_celsius": 38,
            "taux_matiere_vegetale_percent": 3.5,
            "humidite_sortie_percent": 13,
            "ph_laine": 7.1,
            "yield_percentage": 38,
        },
        "C3": {
            "type_de_laine": "TOISON_MORCEAUX",
            "proprete_score": 3,
            "sacs_count": 14,
            "classification": "CLASSE_B_SOUILLEE",
            "temperature_tas_celsius": 36,
            "taux_matiere_vegetale_percent": 4,
            "humidite_sortie_percent": 13.2,
            "ph_laine": 7,
        },
    }

    annex_overrides = {
        "NFN-202": {
            "proprete_score": 2,
            "classification": "CLASSE_B_SOUILLEE",
            "taux_matiere_vegetale_percent": 4.9,
            "humidite_sortie_percent": 13.8,
            "ph_laine": 7.2,
            "yield_percentage": 40,
        },
        "NFN-304": {
            "proprete_score": 2,
            "temperature_tas_celsius": 45,
            "taux_matiere_vegetale_percent": 5.8,
            "humidite_sortie_percent": 14,
            "ph_laine": 7.3,
        },
        "NFN-405": {
            "proprete_score": 2,
            "classification": "CLASSE_B_SOUILLEE",
            "taux_matiere_vegetale_percent": 6.2,
            "humidite_sortie_percent": 13.1,
        },
    }

    users_store = []
    user_index = {}

    for batch in batches:
        defaults = annex_defaults.get(batch["source_type"], {})
        for key_name, value in defaults.items():
            batch.setdefault(key_name, value)
        batch.update(annex_overrides.get(batch["batch_id"], {}))
        batch.setdefault("annex_metadata", {})

        creator_phone = batch.get("creator_phone")
        collector_phone = batch.get("collector_phone")
        source_type = batch.get("source_type")
        wilaya = batch.get("wilaya")
        sector = {
            "C1": "C1_FARMER",
            "C2": "C2_ABATTOIR",
            "C3": "C3_AGGREGATOR",
        }.get(source_type)

        creator_id = ensure_user(users_store, user_index, creator_phone, sector, wilaya)
        collector_id = ensure_user(users_store, user_index, collector_phone, "COLLECTOR", wilaya)

        if creator_id:
            batch["creator_id"] = creator_id
        if collector_id:
            batch["collector_id"] = collector_id

        batch.pop("creator_phone", None)
        batch.pop("collector_phone", None)

    if users_store:
        print(f"[SEED] Inserting {len(users_store)} users...")
        sb.table("users").upsert(users_store, on_conflict="phone_number").execute()

    print(f"[SEED] Inserting {len(batches)} batches...")
    for batch in batches:
        sb.table("batches").upsert(batch, on_conflict="batch_id").execute()

    # ── Alerts ──────────────────────────────────────
    alerts_data = [
        {
            "id": "11111111-1111-4111-8111-111111111202",
            "batch_id": "NFN-202",
            "alert_type": "ALERTE_RENDEMENT_INTELLIGENT",
            "severity": "POINT_ROUGE",
            "is_resolved": False,
            "description": "Lot NFN-202 (Tonte C1). Rendement actuel: 40%. Anomalie: Le rendement tonte doit etre > 55%. Risque de fraude.",
            "action": "Controle fournisseur",
        },
        {
            "id": "22222222-2222-4222-8222-222222222304",
            "batch_id": "NFN-304",
            "alert_type": "ALERTE_AUTO_COMBUSTION",
            "severity": "POINT_ROUGE",
            "is_resolved": False,
            "description": "Lot NFN-304 (Depot D1). Temperature du tas critique (45C). Risque d'incendie ou pourriture.",
            "action": "Isoler le lot",
        },
        {
            "id": "33333333-3333-4333-8333-333333333405",
            "batch_id": "NFN-405",
            "alert_type": "ALERTE_MATIERES_VEGETALES",
            "severity": "POINT_JAUNE",
            "is_resolved": False,
            "description": "Lot NFN-405. Taux de paille > 5%. Action auto: Redirige vers Classe B (Engrais).",
            "action": "Rediriger Classe B",
        },
    ]

    print(f"[SEED] Inserting {len(alerts_data)} alerts...")
    for alert in alerts_data:
        sb.table("alerts").upsert(alert, on_conflict="id").execute()

    print("[SEED] Done. Database seeded successfully.")


if __name__ == "__main__":
    main()
