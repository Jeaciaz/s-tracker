from pydantic import BaseModel, UUID4
from pydantic.color import Color


class SpendingPublic(BaseModel):
    id: UUID4
    amount: float
    timestamp: int
    funnel_id: UUID4

    def dict(self, *args, **kwargs):
        return {**super().dict(*args, **kwargs), 'funnel_id': str(self.funnel_id), 'id': str(self.id)}


class SpendingCreate(BaseModel):
    amount: float
    timestamp: int
    funnel_id: UUID4

    def dict(self, *args, **kwargs):
        return {**super().dict(*args, **kwargs), 'funnel_id': str(self.funnel_id)}
