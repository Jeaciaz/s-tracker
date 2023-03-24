from pydantic import BaseModel
from pydantic.color import Color

from uuid import UUID


class SpendingSinkBase(BaseModel):
    name: str
    limit: float
    color: Color
    emoji: str

    def dict(self, *args, **kwargs):
        return super().dict(*args, **kwargs) | {'color': self.color.as_rgb()}


class SpendingSinkCreate(SpendingSinkBase):
    ...


class SpendingSink(SpendingSinkBase):
    id: UUID
    class Config:
        orm_mode = True
