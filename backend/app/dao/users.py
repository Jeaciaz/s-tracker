import sqlalchemy as sa
import pyotp

from .base import BaseDAO
from .tables import users_table
from ..dto.users import *
from ..exceptions import UserNotFoundException

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
