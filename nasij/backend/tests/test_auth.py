import pytest
from conftest import TEST_PHONE, TEST_PASSWORD

def test_health(client):
    resp = client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_signup_returns_token(auth_tokens):
    assert "access_token" in auth_tokens
    assert len(auth_tokens["access_token"]) > 10


def test_login_returns_sector(auth_tokens):
    assert auth_tokens["sector"] is not None


def test_me_returns_profile(client, auth_headers):
    resp = client.get("/api/auth/me", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "sector" in data
    assert data["sector"] is not None


def test_login_wrong_password(client):
    resp = client.post("/api/auth/login", json={
        "phone": TEST_PHONE,
        "password": "wrongpassword",
    })
    assert resp.status_code == 401


def test_me_no_token(client):
    resp = client.get("/api/auth/me")
    assert resp.status_code == 401


def test_logout(client, auth_headers):
    resp = client.post("/api/auth/logout", headers=auth_headers)
    assert resp.status_code == 200
