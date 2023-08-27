from uuid import uuid4, UUID
from datetime import datetime

import sqlalchemy as sa

from .base import BaseDAO
from .spendings import SpendingDAO
from .tables import funnels_table
from ..database import *
from ..dto.funnels import *
from ..exceptions import FunnelDoesNotExistException
from ..lib.monthly_period import *


class FunnelDAO(BaseDAO):
    def __init__(self, connection: sa.Connection, spendingDao: SpendingDAO):
        super().__init__(connection)
        self._spendingDao = spendingDao

    def from_row(self, row: dict) -> FunnelPublic:
        spendings = [spending.amount for spending 
            in self._spendingDao.get_all(timestamp_from=get_current_period_start())
            if str(spending.funnel_id) == row['id']
        ]
        remaining = row['limit'] - sum(spendings)
        return FunnelPublic(**row | {'remaining': remaining, 
                                     'daily': remaining - (row['limit'] * get_current_period_remaining_days() / get_current_period_length()),
                                    })

    def get_all(self, username: str) -> list[FunnelPublic]:
        result = self._connection.execute(sa.select(funnels_table).where(funnels_table.c.user_name == username)).all()
        return([self.from_row(row._asdict()) for row in result])

    def create(self, funnel: FunnelCreate) -> UUID:
        result = self._connection.execute(sa.insert(funnels_table).values(**{**funnel.dict(), 'id': str(uuid4())}))
        return result.inserted_primary_key[0]

    def update(self, id: UUID, funnel: FunnelCreate):
        result = self._connection.execute(sa.update(funnels_table).where(funnels_table.c.id == str(id)).values(**funnel.dict()))
        if result.rowcount == 0:
            raise FunnelDoesNotExistException()

    def delete(self, id: UUID):
        result = self._connection.execute(sa.delete(funnels_table).where(funnels_table.c.id == str(id)))
        print(result, result.rowcount)
        if result.rowcount == 0:
            raise FunnelDoesNotExistException()
