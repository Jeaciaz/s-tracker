from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class SpendingBase(BaseModel):
    datetime: datetime
    amount: float


class SpendingCreate(SpendingBase):
    ...


class Spending(SpendingBase):
    id: UUID
    spending_sink_id: UUID

    class Config:
        orm_mode = True
