from pydantic import BaseModel, UUID4
from pydantic.color import Color


class FunnelPublic(BaseModel):
    name: str
    limit: float
    color: Color
    emoji: str
    id: UUID4
    remaining: float
    daily: float

    def dict(self, *args, **kwargs):
        return {**super().dict(*args, **kwargs), 'color': self.color.as_hex(), 'id': str(self.id)}


class FunnelCreateBody(BaseModel):
    name: str
    limit: float
    color: Color
    emoji: str

    def dict(self, *args, **kwargs):
        return {**super().dict(*args, **kwargs), 'color': self.color.as_hex()}

class FunnelCreate(FunnelCreateBody):
    user_name: str