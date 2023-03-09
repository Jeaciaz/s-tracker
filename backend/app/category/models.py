from sqlalchemy import String, Float
from sqlalchemy.orm import Mapped, mapped_column, relationship, Session

from ..database import Base
from . import schemas, exceptions


class Category(Base):
    __tablename__ = 'categories'

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(30))
    limit: Mapped[float] = mapped_column(Float)
    color: Mapped[str] = mapped_column(String)
    emoji: Mapped[str] = mapped_column(String)

    spendings = relationship("Spending", back_populates='category')


def get_categories(db: Session) -> list[Category]:
    return db.query(Category).all()


def create_category(db: Session, category: schemas.CategoryCreate) -> Category:
    db_category = Category(name=category.name, limit=category.limit, color=category.color.as_rgb(), emoji=category.emoji)
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category


def update_category(db: Session, category_id: int, category: schemas.CategoryCreate) -> Category:
    db_category = db.get(Category, category_id)
    raise NotImplementedError("Ask Artyom")


def delete_category(db: Session, category_id: int) -> None:
    db_category = db.get(Category, category_id)
    if db_category is None:
        raise exceptions.CategoryDoesNotExistError
    db.delete(db_category)
    db.commit()
