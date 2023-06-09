from fastapi.testclient import TestClient

def get_funnels(client: TestClient):
    return client.get('/funnel')

