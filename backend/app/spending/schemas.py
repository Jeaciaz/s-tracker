from datetime import datetime

from pydantic import BaseModel


class SpendingBase(BaseModel):
    datetime: datetime
    amount: float


class SpendingCreate(SpendingBase):
    ...


class Spending(SpendingBase):
    category_id: int

    class Config:
        orm_mode = True
