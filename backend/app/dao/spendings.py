from uuid import uuid4, UUID
import math
from datetime import datetime

import sqlalchemy as sa

from ..dto.spendings import *
from ..exceptions import SpendingDoesNotExistException
from ..lib.monthly_period import *
from .base import BaseDAO
from .tables import spendings_table, funnels_table, users_table


class SpendingDAO(BaseDAO):
    def get_all(
        self,
        username: str | None = None,
        timestamp_from: int | None = None,
        timestamp_to: int | None = None,
        funnel_id: UUID4 | None = None,
    ) -> list[SpendingPublic]:
        if timestamp_from is None:
            timestamp_from = get_current_period_start()
        if timestamp_to is None:
            timestamp_to = ms_timestamp(datetime.now())

        query = (
            sa.select(spendings_table)
            .where(spendings_table.c.timestamp > timestamp_from)
            .where(spendings_table.c.timestamp < timestamp_to)
        )

        if username is not None:
            query = query.where(
                (spendings_table.c.funnel_id == funnels_table.c.id)
                & (funnels_table.c.user_name == username)
            )

        if funnel_id is not None:
            query = query.where(spendings_table.c.funnel_id == str(funnel_id))

        result = self._connection.execute(query).all()
        return [SpendingPublic(**row._asdict()) for row in result]

    def create(self, spending: SpendingCreate) -> UUID:
        result = self._connection.execute(
            sa.insert(spendings_table).values(
                **{**spending.dict(), "id": str(uuid4())}
                | {"funnel_id": str(spending.funnel_id)}
            )
        )
        return result.inserted_primary_key[0]

    def update(self, id: UUID, spending: SpendingCreate) -> None:
        result = self._connection.execute(
            sa.update(spendings_table)
            .where(spendings_table.c.id == str(id))
            .values(**spending.dict())
        )
        if result.rowcount == 0:
            raise SpendingDoesNotExistException()

    def delete(self, id: UUID) -> None:
        result = self._connection.execute(
            sa.delete(spendings_table).where(spendings_table.c.id == str(id))
        )
        if result.rowcount == 0:
            raise SpendingDoesNotExistException()
