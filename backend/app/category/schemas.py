from pydantic import BaseModel
from pydantic.color import Color


class CategoryBase(BaseModel):
    name: str
    limit: float
    color: Color
    emoji: str


class CategoryCreate(CategoryBase):
    ...


class Category(CategoryBase):

    class Config:
        orm_mode = True
