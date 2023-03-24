import datetime

from fastapi import FastAPI

from .schemas import Spending
from ..spending_sinks.test_spending_sinks import get_spending_sinks


test_spending = {
    "datetime": datetime.datetime.now().isoformat(),
    "amount": 1000,
}


def get_spendings(client: FastAPI):
    return client.get('/spendings')


def test_create_spending(client: FastAPI):
    sink = get_spending_sinks(client).json()[0]
    response = client.post(f'/spendings/{sink["id"]}', json=test_spending)

    assert response.status_code == 201, response.text
    data = response.json()
    assert 'id' in data
    assert any(spending == data for spending in get_spendings(client).json())


def test_get_spendings(client: FastAPI):
    response = get_spendings(client)

    assert response.status_code == 200, response.text
    spendings = response.json()
    assert isinstance(spendings, list)
    assert all(Spending.validate(spending) for spending in spendings)


def test_put_spendings(client: FastAPI):
    spending = get_spendings(client).json()[0]
    test_spending_with_ids = test_spending | {
        'id': spending['id'],
        'spending_sink_id': spending['spending_sink_id']
    }
    assert spending != test_spending

    response = client.put(f'/spendings/{spending["id"]}', json=test_spending)

    assert response.status_code == 200, response.text
    spendings = get_spendings(client).json()

    assert any(spending_data == test_spending_with_ids for spending_data in spendings)


def test_delete_spendings(client: FastAPI):
    spending_id = get_spendings(client).json()[0]['id']
    response = client.delete(f'/spendings/{spending_id}')

    assert response.status_code == 200, response.text
    spendings = get_spendings(client).json()

    assert not any(spending['id'] == spending_id for spending in spendings)
