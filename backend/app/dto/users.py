from pydantic import BaseModel
from typing import Literal

class UserPublic(BaseModel):
    username: str


class UserLogin(BaseModel):
    username: str
    otp: str

class UserCreate(BaseModel):
    username: str
    otp_secret: str
    otp_example: str


class NewOtp(BaseModel):
    secret: str
    uri: str

class UserJwtPayload(BaseModel):
    username: str
    exp: int
    iat: int
    type: Literal['access'] | Literal['refresh']

class JwtPair(BaseModel):
    refresh: str
    access: str

class JwtRefreshBody(BaseModel):
    refresh: str

class GenerateSecretBody(BaseModel):
    username: str