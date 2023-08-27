import sqlalchemy as sa
import pyotp
import jwt

from .base import BaseDAO
from .tables import users_table, jwt_blacklist_table
from ..dto.users import *
from ..exceptions import UserNotFoundException, JwtTokenBlacklistedException
from ..config import JWT_SECRET

class UsersDAO(BaseDAO):
    def create(self, user: UserCreate):
        # The secret is stored in plain text because it's needed to validate future login attempts. It is pretty unsafe, but as it's a pretty small non-commercial app, it's unlikely to be attacked. It's a major stopping point for growth though.
        # When it must become safe, we should move the database to a separate server and arrange proper access policies. Also the secrets should be two-way encrypted using a secret key from the main server.
        self._connection.execute(sa.insert(users_table).values({'username': user.username, 'otp_secret': user.otp_secret}))

    def check_username(self, username: str):
        """Returns whether username is valid (i.e. not taken)"""
        return len(self._connection.execute(sa.select(users_table).where(users_table.c.username == username)).all()) == 0

    def check_auth(self, username: str, otp: str):
        try:
            username, secret = self._connection.execute(sa.select(users_table).where(users_table.c.username == username)).one()
            return pyotp.TOTP(secret).verify(otp)
        except:
            raise UserNotFoundException()
    
    def _check_token_blacklist(self, username: str, token_iat: int):
        blacklist_entry = self._connection.execute(sa.select(jwt_blacklist_table).where(jwt_blacklist_table.c.username == username)).one_or_none()
        return blacklist_entry is None or blacklist_entry[1] < token_iat 

    def decode_token(self, token: str):
        decoded = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        if not self._check_token_blacklist(decoded['username'], decoded['iat']):
            raise JwtTokenBlacklistedException()
        return decoded

    def invalidate_tokens(self, username: str, iat_until: int):
        """Invalidates all tokens forged before `iat_until` for user `username`"""
        self._connection.execute(sa.delete(jwt_blacklist_table).where(jwt_blacklist_table.c.username == username))
        self._connection.execute(sa.insert(jwt_blacklist_table).values({'username': username, 'iat_until': iat_until}))