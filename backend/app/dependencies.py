from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import Connection
from typing import Annotated
import jwt

from .database import engine
from .exceptions import JwtTokenBlacklistedException

from .dao.funnels import FunnelDAO
from .dao.spendings import SpendingDAO
from .dao.users import UsersDAO
from .dto.users import UserJwtPayload


def _get_db_conn():
    with engine.begin() as conn:
        yield conn


_DepDbConn = Annotated[Connection, Depends(_get_db_conn)]


def get_funnel_dao(conn: _DepDbConn):
    return FunnelDAO(conn, SpendingDAO(conn))


DepFunnelDAO = Annotated[FunnelDAO, Depends(get_funnel_dao)]


def get_spending_dao(conn: _DepDbConn):
    return SpendingDAO(conn)


DepSpendingDAO = Annotated[SpendingDAO, Depends(get_spending_dao)]


def get_user_dao(conn: _DepDbConn):
    return UsersDAO(conn)


DepUserDAO = Annotated[UsersDAO, Depends(get_user_dao)]

auth_scheme = HTTPBearer()


def get_user_auth(
    authorization: Annotated[HTTPAuthorizationCredentials, Depends(auth_scheme)],
    user_dao: DepUserDAO,
):
    try:
        decoded = user_dao.decode_token(authorization.credentials)
        if decoded["type"] == "refresh":
            raise HTTPException(
                status_code=403, detail="Only access tokens are accepted"
            )
        return UserJwtPayload(**decoded)
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=403, detail="Authorization expired")
    except JwtTokenBlacklistedException:
        raise HTTPException(status_code=403, detail="Token is blacklisted")
    except:
        raise HTTPException(status_code=400, detail="Invalid token")


VoidDepUserAuth = Depends(get_user_auth)
DepUserAuth = Annotated[UserJwtPayload, Depends(get_user_auth)]
