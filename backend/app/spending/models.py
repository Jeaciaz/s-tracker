from datetime import datetime

from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship, Session

from ..database import Base
from . import schemas, exceptions


class Spending(Base):
    __tablename__ = 'spendings'

    id: Mapped[int] = mapped_column(primary_key=True)
    amount: Mapped[float] = mapped_column(String)
    datetime: Mapped[datetime] = mapped_column(DateTime)
    category_id: Mapped[int] = mapped_column(ForeignKey('categories.id'))

    category = relationship("Category", back_populates="spendings")


def get_spendings(db: Session, date_from: datetime | None) -> list[Spending]:
    if date_from is None:
        return db.query(Spending).all()
    return db.query(Spending).filter(Spending.datetime > date_from).all()


def create_spending(db: Session, spending: schemas.SpendingCreate, category_id: int) -> Spending:
    db_spending = Spending(**spending.dict(), category_id=category_id)
    db.add(db_spending)
    db.commit()
    db.refresh(db_spending)
    return db_spending


def update_spending(db: Session, spending: schemas.SpendingCreate, spending_id: int) -> Spending:
    raise NotImplementedError("Ask Artyom")


def remove_spending(db: Session, spending_id: int) -> None:
    db_spending = db.get(Spending, spending_id)
    if db_spending is None:
        raise exceptions.SpendingDoesNotExistError
    db.delete(db_spending)
    db.commit()
