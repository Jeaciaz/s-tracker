from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Annotated
import jwt

from .database import engine
from .exceptions import JwtTokenBlacklistedException

from .dao.funnels import FunnelDAO
from .dao.spendings import SpendingDAO
from .dao.users import UsersDAO
from .dto.users import UserJwtPayload


def _get_funnel_dao():
    with engine.begin() as conn:
        yield FunnelDAO(conn, SpendingDAO(conn))


DepFunnelDAO = Annotated[FunnelDAO, Depends(_get_funnel_dao)]


def _get_spending_dao():
    with engine.begin() as conn:
        yield SpendingDAO(conn)


DepSpendingDAO = Annotated[SpendingDAO, Depends(_get_spending_dao)]


def _get_user_dao():
    with engine.begin() as conn:
        yield UsersDAO(conn)


DepUserDAO = Annotated[UsersDAO, Depends(_get_user_dao)]

auth_scheme = HTTPBearer()


def _get_user_auth(
    authorization: Annotated[HTTPAuthorizationCredentials, Depends(auth_scheme)],
    user_dao: DepUserDAO,
):
    try:
        decoded = user_dao.decode_token(authorization.credentials)
        print(decoded)
        return UserJwtPayload(**decoded)
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=403, detail="Authorization expired")
    except JwtTokenBlacklistedException:
        raise HTTPException(status_code=403, detail="Token is blacklisted")
    except:
        raise HTTPException(status_code=400, detail="Invalid token")


VoidDepUserAuth = Depends(_get_user_auth)
DepUserAuth = Annotated[UserJwtPayload, Depends(_get_user_auth)]
