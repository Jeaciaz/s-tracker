from fastapi.testclient import TestClient

from ..dto.funnels import *
from .shared import *

test_funnel = {
    "name": "Test",
    "limit": 20000,
    "color": "#32ceba",
    "emoji": "🎀",
    "user_name": "test",
}


def create_funnel(client: TestClient):
    return client.post("/funnel", json=test_funnel)


def test_create_funnel(client: TestClient, fake_auth):
    """Tests whether the route to create a funnel actually does so."""
    response = create_funnel(client)
    assert response.status_code == 201, response.text

    funnel_id = response.json()
    data = get_funnels(client).json()
    assert any(funnel["id"] == funnel_id for funnel in data)


def test_get_funnels(client: TestClient, fake_auth):
    """Tests that the route to retrieve all funnels returns a proper list."""
    response = get_funnels(client)
    assert response.status_code == 200, response.text
    data = response.json()
    assert isinstance(data, list)
    assert all(FunnelPublic.validate(funnel) for funnel in data)


def test_update_funnel(client: TestClient, fake_auth):
    """Tests that updating a funnel actually works"""
    funnel_id = get_funnels(client).json()[0]["id"]

    response = client.put(f"/funnel/{funnel_id}", json=test_funnel)
    assert response.status_code == 204

    all_funnels = get_funnels(client).json()
    assert any(
        {key: value for key, value in test_funnel.items() if key != "user_name"}.items()
        <= (funnel | {"id": funnel_id}).items()
        for funnel in all_funnels
    )


def test_delete_funnel(client: TestClient, fake_auth):
    """Tests that deleting a funnel actually does it"""
    all_funnels = get_funnels(client).json()
    funnel_id = all_funnels[0]["id"]
    response = client.delete(f"/funnel/{funnel_id}")
    assert response.status_code == 204

    all_funnels = get_funnels(client).json()
    assert not any(funnel["id"] == funnel_id for funnel in all_funnels)


def test_funnel_non_auth(client: TestClient):
    """Tests that all routes return 403 when unauthenticated"""
    get = client.get("/funnel/")
    post = client.post("/funnel/")
    put = client.put("/funnel/123")
    delete = client.delete("/funnel/123")

    assert all(req.status_code == 403 for req in (get, post, put, delete))
