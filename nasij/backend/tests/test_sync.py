import pytest
from conftest import TEST_BATCH_ID
from app.config import get_settings
from supabase import create_client

SYNC_BATCH_A = "SYNC-TEST-A-8881"
SYNC_BATCH_B = "SYNC-TEST-B-8882"
SYNC_BATCH_C = "SYNC-TEST-C-8883"


def _sb():
    s = get_settings()
    return create_client(s.supabase_url, s.supabase_service_role_key)


def _cleanup(batch_id: str) -> None:
    try:
        sb = _sb()
        sb.table("alerts").delete().eq("batch_id", batch_id).execute()
        sb.table("batches").delete().eq("batch_id", batch_id).execute()
    except Exception:
        pass


@pytest.fixture(scope="module", autouse=True)
def cleanup(client):
    for bid in [SYNC_BATCH_A, SYNC_BATCH_B, SYNC_BATCH_C]:
        _cleanup(bid)
    yield
    for bid in [SYNC_BATCH_A, SYNC_BATCH_B, SYNC_BATCH_C]:
        _cleanup(bid)



def _base_item(batch_id: str, status="PENDING_PICKUP") -> dict:
    return {
        "batch_id": batch_id,
        "source_type": "C1",
        "breed": "REMBI",
        "wilaya": "Djelfa",
        "status": status,
    }


def test_bulk_sync_three_items(client):
    resp = client.post("/api/sync", json={
        "device_id": "test-device-001",
        "items": [
            _base_item(SYNC_BATCH_A),
            _base_item(SYNC_BATCH_B),
            _base_item(SYNC_BATCH_C),
        ],
    })
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data["synced"] == 3
    assert data["failed"] == 0
    assert data["errors"] == []


def test_sync_duplicate_is_idempotent(client):
    """Sending the same batch again should upsert, not fail."""
    resp = client.post("/api/sync", json={
        "device_id": "test-device-001",
        "items": [_base_item(SYNC_BATCH_A)],
    })
    assert resp.status_code == 200
    assert resp.json()["synced"] == 1
    assert resp.json()["failed"] == 0


def test_sync_with_weight_triggers_alert(client):
    """Send a batch with large weight loss — sync should create E1 alert."""
    heavy_id = "SYNC-HEAVY-9991"
    _cleanup(heavy_id)

    resp = client.post("/api/sync", json={
        "device_id": "test-device-field",
        "items": [{
            **_base_item(heavy_id, "AT_D1_STOCKAGE"),
            "weight_raw_e1_kg": 100.0,
            "weight_after_handclean_kg": 50.0,
        }],
    })
    assert resp.status_code == 200
    assert resp.json()["synced"] == 1

    alerts_resp = client.get(f"/api/alerts?batch_id={heavy_id}")
    types = [a["alert_type"] for a in alerts_resp.json()]
    assert "E1_PERTE_EN_ROUTE" in types or "A1_RENDEMENT" in types

    _cleanup(heavy_id)


def test_sync_pending_delta(client):
    resp = client.get("/api/sync/pending")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_sync_pending_delta_with_since(client):
    resp = client.get("/api/sync/pending?since=2020-01-01T00:00:00Z")
    assert resp.status_code == 200
    rows = resp.json()
    assert isinstance(rows, list)
    assert len(rows) > 0
