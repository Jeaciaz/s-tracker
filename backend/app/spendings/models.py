from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import Float, DateTime, ForeignKey, update
from sqlalchemy.orm import Mapped, mapped_column, relationship, Session

from ..database import Base
from . import schemas, exceptions


class Spending(Base):
    __tablename__ = 'spendings'

    id: Mapped[UUID] = mapped_column(primary_key=True)
    amount: Mapped[float] = mapped_column(Float)
    datetime: Mapped[datetime] = mapped_column(DateTime)
    spending_sink_id: Mapped[UUID] = mapped_column(ForeignKey('spending_sinks.id'))

    spending_sink = relationship("SpendingSink", back_populates="spendings")


def get_spendings(db: Session, date_from: datetime | None) -> list[Spending]:
    if date_from is None:
        return db.query(Spending).all()
    return db.query(Spending).filter(Spending.datetime > date_from).all()


def create_spending(db: Session, spending: schemas.SpendingCreate, spending_sink_id: UUID) -> Spending:
    db_spending = Spending(**spending.dict(), spending_sink_id=spending_sink_id, id=uuid4())
    db.add(db_spending)
    db.commit()
    db.refresh(db_spending)
    return db_spending


def update_spending(db: Session, spending: schemas.SpendingCreate, spending_id: UUID) -> None:
    db.execute(
        update(Spending)
        .where(Spending.id == spending_id)
        .values(**spending.dict())
    )
    db.commit()


def remove_spending(db: Session, spending_id: UUID) -> None:
    db_spending = db.get(Spending, spending_id)
    if db_spending is None:
        raise exceptions.SpendingDoesNotExistError
    db.delete(db_spending)
    db.commit()
