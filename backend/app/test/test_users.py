from fastapi.testclient import TestClient
import pyotp

from ..dto.users import *


def check_auth(client: TestClient, access: str):
    assert (
        client.get(
            "/user/decode/", headers={"Authorization": f"Bearer {access}"}
        ).status_code
        == 200
    )


def test_register(client: TestClient):
    test_username = "Test user"
    otp_secret_response = client.post(
        "/user/generate-otp-secret/", json={"username": test_username}
    )
    assert otp_secret_response.status_code == 200, {"secret", "uri"}.issubset(
        otp_secret_response.json()
    )

    secret = otp_secret_response.json()["secret"]
    register_response = client.post(
        "/user/",
        json={
            "username": test_username,
            "otp_secret": secret,
            "otp_example": pyotp.TOTP(secret).now(),
        },
    )
    assert register_response.status_code == 200
    tokens = register_response.json()

    check_auth(client=client, access=tokens["access"])


def test_login(client: TestClient, user_data: dict[str, str]):
    login_response = client.post(
        "/user/login/",
        json={
            "username": user_data["username"],
            "otp": pyotp.TOTP(user_data["otp_secret"]).now(),
        },
    )
    tokens = login_response.json()
    assert login_response.status_code == 200, {"refresh", "access"}.issubset(
        tokens.keys()
    )
    check_auth(client=client, access=tokens["access"])


def test_refresh(client: TestClient, user_data: dict[str, str]):
    tokens = client.post(
        "/user/login/",
        json={
            "username": user_data["username"],
            "otp": pyotp.TOTP(user_data["otp_secret"]).now(),
        },
    ).json()

    refresh_response = client.post(
        "/user/refresh/", json={"refresh": tokens["refresh"]}
    )
    assert refresh_response.status_code == 200, {"refresh, access"}.issubset(
        refresh_response.json().keys()
    )

    # check the used token is invalidated
    assert (
        client.post("/user/refresh/", json={"refresh": tokens["refresh"]}).status_code
        == 403
    )
