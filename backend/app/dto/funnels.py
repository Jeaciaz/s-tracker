from pydantic import BaseModel, UUID4
from pydantic.color import Color


class FunnelPublic(BaseModel):
    name: str
    limit: float
    color: Color
    emoji: str
    id: UUID4
    user_name: str
    remaining: float
    daily: float

    def dict(self, *args, **kwargs):
        return {**super().dict(*args, **kwargs), 'color': self.color.as_hex(), 'id': str(self.id)}


class FunnelCreate(BaseModel):
    name: str
    limit: float
    color: Color
    emoji: str
    user_name: str

    def dict(self, *args, **kwargs):
        return {**super().dict(*args, **kwargs), 'color': self.color.as_hex()}
