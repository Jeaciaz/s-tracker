from datetime import datetime

from fastapi.testclient import TestClient

from ..dto.spendings import *
from ..lib.monthly_period import ms_timestamp
from .shared import *

test_spending = {
    "amount": 250,
    "timestamp": ms_timestamp(datetime.now()),
}


def get_spendings(client: TestClient):
    return client.get("/spending")


def test_create_spending(client: TestClient, fake_auth):
    funnel_id = get_funnels(client).json()[0]["id"]
    response = client.post("/spending", json=test_spending | {"funnel_id": funnel_id})
    assert response.status_code == 201, response.text

    spending_id = response.json()
    spendings = get_spendings(client).json()
    assert any(spending["id"] == spending_id for spending in spendings)


def test_get_spendings(client: TestClient, fake_auth):
    response = get_spendings(client)
    assert response.status_code == 200, response.text
    data = response.json()
    assert isinstance(data, list)
    assert all(SpendingPublic.validate(spending) for spending in data)


def test_update_spending(client: TestClient, fake_auth):
    target_spending = get_spendings(client).json()[0]
    response = client.put(
        f'/spending/{target_spending["id"]}',
        json=test_spending | {"funnel_id": target_spending["funnel_id"]},
    )
    assert response.status_code == 204

    all_spendings = get_spendings(client).json()
    assert any(
        (test_spending | {"id": target_spending["id"]}).items() <= spending.items()
        for spending in all_spendings
    )


def test_delete_spending(client: TestClient, fake_auth):
    spending_id = get_spendings(client).json()[0]["id"]
    response = client.delete(f"/spending/{spending_id}")
    assert response.status_code == 204

    all_spendings = get_spendings(client).json()
    assert not any(spending["id"] == spending_id for spending in all_spendings)


def test_funnel_non_auth(client: TestClient):
    """Tests that all routes return 403 when unauthenticated"""
    get = client.get("/spending/")
    post = client.post("/spending/")
    put = client.put("/spending/123")
    delete = client.delete("/spending/123")

    assert all(req.status_code == 403 for req in (get, post, put, delete))
