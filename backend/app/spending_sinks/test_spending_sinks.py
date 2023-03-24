from fastapi import FastAPI

from . import schemas

test_sink = {
    "name": "Test",
    "limit": 20000,
    "color": "rgb(50, 206, 186)",
    "emoji": "🎀"
}


def get_spending_sinks(client: FastAPI):
    return client.get('/spending-sinks')


def create_spending_sink(client: FastAPI):
    return client.post('/spending-sinks', json=test_sink)


def test_create_spending_sink(client: FastAPI):
    """Tests whether the route to create a sink actually does so."""
    response = create_spending_sink(client)
    print(response.status_code)
    print(__name__)
    assert response.status_code == 201, response.text

    data = response.json()
    assert data['name'] == 'Test'
    assert 'id' in data
    spending_sink_id = data['id']

    get_data = client.get('/spending-sinks').json()
    assert any(sink['id'] == spending_sink_id for sink in get_data)


def test_get_spending_sinks(client: FastAPI):
    """Tests that the route to retrieve all sinks returns a proper list."""
    response = get_spending_sinks(client)
    assert response.status_code == 200, response.text
    data = response.json()
    assert isinstance(data, list)
    assert all(schemas.SpendingSink.validate(sink) for sink in data)


def test_put_spending_sinks(client: FastAPI):
    sink_id = get_spending_sinks(client).json()[0]['id']

    response = client.put(f'/spending-sinks/{sink_id}', json=test_sink)
    assert response.status_code == 200, response.text

    all_sinks = get_spending_sinks(client).json()
    assert any(sink == test_sink | {"id": sink_id} for sink in all_sinks)


def test_delete_spending_sinks(client: FastAPI):
    all_sinks = get_spending_sinks(client).json()
    sink_id = all_sinks[0]['id']
    response = client.delete(f'/spending-sinks/{sink_id}')
    assert response.status_code == 200, response.text

    all_sinks = get_spending_sinks(client).json()
    assert not any(sink['id'] == sink_id for sink in all_sinks)
