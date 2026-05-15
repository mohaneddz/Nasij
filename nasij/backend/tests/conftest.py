import pytest
from fastapi.testclient import TestClient
from supabase import create_client

from app.main import app
from app.config import get_settings

TEST_PHONE = "0699000001"
TEST_PASSWORD = "testpass123"
TEST_BATCH_ID = "TEST-NASIJ-9999"

TEST_EMAIL = f"{TEST_PHONE}@nfn.local"


def _ensure_test_user() -> None:
    """Create the test user via admin API so email confirmation is not needed."""
    s = get_settings()
    admin = create_client(s.supabase_url, s.supabase_service_role_key)

    try:
        users_list = admin.auth.admin.list_users()
        existing = next(
            (u for u in users_list if u.email == TEST_EMAIL),
            None,
        )
        if existing:
            admin.auth.admin.update_user_by_id(
                str(existing.id),
                {"password": TEST_PASSWORD, "email_confirm": True},
            )
            admin.table("users").upsert({
                "id": str(existing.id),
                "phone_number": TEST_PHONE,
                "sector": "C1_FARMER",
                "role": "C1_FARMER",
                "wilaya": "Alger",
                "full_name": "Test Farmer",
                "is_approved": True,
            }).execute()
            return

        created = admin.auth.admin.create_user({
            "email": TEST_EMAIL,
            "password": TEST_PASSWORD,
            "email_confirm": True,
            "user_metadata": {
                "phone": TEST_PHONE,
                "sector": "C1_FARMER",
                "wilaya": "Alger",
                "full_name": "Test Farmer",
            },
        })
        admin.table("users").upsert({
            "id": str(created.user.id),
            "phone_number": TEST_PHONE,
            "sector": "C1_FARMER",
            "role": "C1_FARMER",
            "wilaya": "Alger",
            "full_name": "Test Farmer",
            "is_approved": True,
        }).execute()
    except Exception as exc:
        print(f"[conftest] _ensure_test_user warning: {exc}")


@pytest.fixture(scope="session")
def client():
    _ensure_test_user()
    with TestClient(app) as c:
        yield c


@pytest.fixture(scope="session")
def auth_tokens(client):
    login_resp = client.post("/api/auth/login", json={
        "phone": TEST_PHONE,
        "password": TEST_PASSWORD,
    })
    assert login_resp.status_code == 200, login_resp.text
    return login_resp.json()


@pytest.fixture(scope="session")
def auth_headers(auth_tokens):
    return {"Authorization": f"Bearer {auth_tokens['access_token']}"}
