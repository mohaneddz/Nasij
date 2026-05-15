import pytest


def test_alerts_list_returns_array(client):
    resp = client.get("/api/alerts")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_alerts_filter_by_severity(client):
    resp = client.get("/api/alerts?severity=POINT_ROUGE")
    assert resp.status_code == 200
    for alert in resp.json():
        assert alert["severity"] == "POINT_ROUGE"


def test_alerts_filter_unresolved(client):
    resp = client.get("/api/alerts?resolved=false")
    assert resp.status_code == 200
    for alert in resp.json():
        assert alert["is_resolved"] is False


def test_alerts_schema(client):
    resp = client.get("/api/alerts")
    assert resp.status_code == 200
    for alert in resp.json():
        assert "id" in alert
        assert "alert_type" in alert
        assert "severity" in alert
        assert "is_resolved" in alert


def test_resolve_nonexistent_alert(client):
    resp = client.patch("/api/alerts/00000000-0000-0000-0000-000000000000/resolve")
    assert resp.status_code == 404


def test_my_batches_alerts_invalid_user(client):
    resp = client.get("/api/alerts/my-batches?user_id=00000000-0000-0000-0000-000000000000")
    assert resp.status_code == 200
    assert resp.json() == []
