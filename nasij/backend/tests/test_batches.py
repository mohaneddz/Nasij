import pytest
from conftest import TEST_BATCH_ID
from app.config import get_settings
from supabase import create_client


def _sb():
    s = get_settings()
    return create_client(s.supabase_url, s.supabase_service_role_key)


def _cleanup_batch(batch_id: str) -> None:
    try:
        sb = _sb()
        sb.table("alerts").delete().eq("batch_id", batch_id).execute()
        sb.table("batches").delete().eq("batch_id", batch_id).execute()
    except Exception:
        pass


@pytest.fixture(scope="module", autouse=True)
def cleanup(client, auth_headers):
    _cleanup_batch(TEST_BATCH_ID)
    yield
    _cleanup_batch(TEST_BATCH_ID)


def test_create_batch(client, auth_headers):
    resp = client.post("/api/batches", headers=auth_headers, json={
        "batch_id": TEST_BATCH_ID,
        "source_type": "C1",
        "breed": "OULED_DJELLAL",
        "wilaya": "Tamanrasset",
        "type_de_laine": "TOISON_ENTIERE",
        "estimated_sheep_count": 25,
        "location_lat": 22.785,
        "location_lng": 5.523,
    })
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["batch_id"] == TEST_BATCH_ID
    assert data["status"] == "PENDING_PICKUP"


def test_batch_appears_in_pending(client):
    resp = client.get("/api/batches/pending")
    assert resp.status_code == 200
    ids = [b["batch_id"] for b in resp.json()]
    assert TEST_BATCH_ID in ids


def test_get_batch(client):
    resp = client.get(f"/api/batches/{TEST_BATCH_ID}")
    assert resp.status_code == 200
    assert resp.json()["source_type"] == "C1"


def test_collect(client, auth_headers):
    resp = client.post(f"/api/batches/{TEST_BATCH_ID}/collect", headers=auth_headers, json={
        "purchase_price_dzd": 18000.0,
        "weight_raw_e1_kg": 110.0,
        "sacs_count": 6,
        "proprete_score": 3,
        "type_de_laine": "TOISON_ENTIERE",
    })
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data["status"] == "COLLECTED_BY_BUYER"
    assert data["weight_raw_e1_kg"] == 110.0


def test_collect_wrong_state(client, auth_headers):
    resp = client.post(f"/api/batches/{TEST_BATCH_ID}/collect", headers=auth_headers, json={
        "purchase_price_dzd": 1000.0,
        "weight_raw_e1_kg": 50.0,
    })
    assert resp.status_code == 409


def test_d1_intake(client):
    resp = client.patch(f"/api/batches/{TEST_BATCH_ID}/d1-intake", json={
        "weight_received_d1_kg": 105.0,
        "stockage_zone": "Zone B",
    })
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data["status"] == "AT_D1_STOCKAGE"
    assert data["stockage_zone"] == "Zone B"
    assert data["annex_metadata"]["weight_received_d1_kg"] == 105.0


def test_d1_intake_triggers_alert_on_big_loss(client, auth_headers):
    """Create a separate batch, declare 100kg, receive only 60kg — expect E1 alert."""
    spike_id = TEST_BATCH_ID + "-SPIKE"
    _cleanup_batch(spike_id)

    client.post("/api/batches", headers=auth_headers, json={
        "batch_id": spike_id,
        "source_type": "C1",
        "breed": "REMBI",
        "wilaya": "Ghardaia",
    })
    client.post(f"/api/batches/{spike_id}/collect", headers=auth_headers, json={
        "purchase_price_dzd": 10000.0,
        "weight_raw_e1_kg": 100.0,
    })
    client.patch(f"/api/batches/{spike_id}/d1-intake", json={
        "weight_received_d1_kg": 60.0,
    })

    alerts_resp = client.get(f"/api/alerts?batch_id={spike_id}")
    assert alerts_resp.status_code == 200
    types = [a["alert_type"] for a in alerts_resp.json()]
    assert "E1_PERTE_EN_ROUTE" in types

    _cleanup_batch(spike_id)


def test_d1_clean(client):
    resp = client.patch(f"/api/batches/{TEST_BATCH_ID}/d1-clean", json={
        "weight_after_handclean_kg": 88.0,
        "taux_matiere_vegetale_percent": 2.0,
        "classification": "CLASSE_A_PROPRE",
    })
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data["weight_after_handclean_kg"] == 88.0


def test_d1_clean_fires_vegetable_alert(client):
    """Re-send with high vegetable matter — should create ALERTE_MATIERES_VEGETALES."""
    resp = client.patch(f"/api/batches/{TEST_BATCH_ID}/d1-clean", json={
        "weight_after_handclean_kg": 88.0,
        "taux_matiere_vegetale_percent": 8.0,
    })
    assert resp.status_code == 200
    alerts_resp = client.get(f"/api/alerts?batch_id={TEST_BATCH_ID}")
    types = [a["alert_type"] for a in alerts_resp.json()]
    assert "ALERTE_MATIERES_VEGETALES" in types


def test_d2_wash(client):
    resp = client.patch(f"/api/batches/{TEST_BATCH_ID}/d2-wash", json={
        "weight_clean_d2_kg": 52.0,
        "water_temp_celsius": 65.0,
        "detergent_type": "Bio",
        "humidite_sortie_percent": 12.0,
        "ph_laine": 7.2,
        "final_destination": "D3_TEXTILES",
    })
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data["status"] == "AT_D2_LAVAGE"
    assert data["final_destination"] == "D3_TEXTILES"


def test_d2_wash_bad_destination(client):
    resp = client.patch(f"/api/batches/{TEST_BATCH_ID}/d2-wash", json={
        "weight_clean_d2_kg": 52.0,
        "final_destination": "INVALID",
    })
    assert resp.status_code == 422


def test_transform(client):
    resp = client.patch(f"/api/batches/{TEST_BATCH_ID}/transform", json={
        "product_type": "Panneaux Isolants",
        "fiber_length_mm": 78.0,
        "finesse_micron": 23.5,
        "humidity_percent": 9.8,
        "target_density_kg_m3": 15.0,
        "total_units_produced": 200,
    })
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data["status"] == "READY_FOR_SALE"
    assert data["is_ready_for_sale"] is True


def test_list_batches_filter(client):
    resp = client.get("/api/batches?status=READY_FOR_SALE")
    assert resp.status_code == 200
    statuses = {b["status"] for b in resp.json()}
    assert statuses == {"READY_FOR_SALE"}


def test_batch_not_found(client):
    resp = client.get("/api/batches/NON-EXISTENT-BATCH")
    assert resp.status_code == 404
