from fastapi import APIRouter, status, HTTPException
from datetime import datetime, timezone, timedelta
import pyotp
import jwt

from ..dependencies import DepUserDAO, DepUserAuth
from ..exceptions import JwtTokenBlacklistedException
from ..dto.users import *
from ..config import JWT_SECRET

router = APIRouter(prefix="/user", tags=["user"])


def generate_jwt(username: str, ttl: int, type: Literal["access"] | Literal["refresh"]):
    return jwt.encode(
        {
            "username": username,
            "exp": timedelta(seconds=ttl) + datetime.now(tz=timezone.utc),
            "iat": datetime.now(tz=timezone.utc),
            "type": type,
        },
        JWT_SECRET,
    )


def generate_jwt_pair(username: str):
    return JwtPair(
        access=generate_jwt(username, 30 * 60, "access"),  # access ttl = 30 min
        refresh=generate_jwt(
            username, 7 * 24 * 60 * 60, "refresh"
        ),  # refresh ttl = 7 days
    )


@router.post(
    "/generate-otp-secret",
    summary="Generate an OTP secret for further authentication",
    status_code=status.HTTP_200_OK,
    response_model=NewOtp,
)
def generate_otp_secret(body: GenerateSecretBody, user_dao: DepUserDAO):
    username = body.username
    if not user_dao.check_username(username):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Username already taken"
        )
    secret = pyotp.random_base32()
    return NewOtp(
        secret=secret,
        uri=pyotp.totp.TOTP(secret).provisioning_uri(
            name=username, issuer_name="₪ Tracker"
        ),
    )


@router.post(
    "/",
    summary="Create new user with OTP secret, verifying provided OTP against it",
    status_code=status.HTTP_200_OK,
    response_model=JwtPair,
)
def create_user(user: UserCreate, user_dao: DepUserDAO):
    if not pyotp.TOTP(user.otp_secret).verify(user.otp_example):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP"
        )
    user_dao.create(user)
    return generate_jwt_pair(user.username)


@router.post(
    "/login",
    summary="Log into an account",
    status_code=status.HTTP_200_OK,
    response_model=JwtPair,
)
def login(user: UserLogin, user_dao: DepUserDAO):
    if not user_dao.check_auth(username=user.username, otp=user.otp):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Invalid password"
        )
    return generate_jwt_pair(user.username)


@router.post(
    "/refresh",
    summary="Refresh a pair of tokens",
    status_code=status.HTTP_200_OK,
    response_model=JwtPair,
)
def refresh_pair(body: JwtRefreshBody, user_dao: DepUserDAO):
    try:
        decoded = user_dao.decode_token(body.refresh)
        user_dao.invalidate_tokens(decoded["username"], decoded["iat"])
        return generate_jwt_pair(decoded["username"])
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Refresh token is expired"
        )
    except JwtTokenBlacklistedException:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Refresh token is blacklisted"
        )
    except:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid token"
        )


@router.get(
    "/decode",
    summary="Internal method, checks auth and returns decoded user",
    status_code=status.HTTP_200_OK,
    response_model=UserJwtPayload,
)
def check_auth(user: DepUserAuth):
    return user
