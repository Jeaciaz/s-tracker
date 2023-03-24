from sqlalchemy import String, Float, update, delete
from sqlalchemy.orm import Mapped, mapped_column, relationship, Session
from uuid import UUID, uuid4

from ..database import Base
from . import schemas, exceptions

class SpendingSink(Base):
    __tablename__ = 'spending_sinks'

    id: Mapped[UUID] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(30))
    limit: Mapped[float] = mapped_column(Float)
    color: Mapped[str] = mapped_column(String(30))
    emoji: Mapped[str] = mapped_column(String(1))

    spendings = relationship("Spending", back_populates="spending_sink", cascade="all, delete, delete-orphan")


def get_spending_sinks(db: Session) -> list[SpendingSink]:
    return db.query(SpendingSink).all()


def create_spending_sink(db: Session, spending_sink: schemas.SpendingSinkCreate) -> None:
    db_spending_sink = SpendingSink(**spending_sink.dict(), id=uuid4())
    db.add(db_spending_sink)
    db.commit()
    db.refresh(db_spending_sink)
    return db_spending_sink


def update_spending_sink(db: Session, spending_sink: schemas.SpendingSinkCreate, spending_sink_id: UUID) -> None:
    db.execute(
        update(SpendingSink)
        .where(SpendingSink.id == spending_sink_id)
        .values(**spending_sink.dict())
    )
    db.commit()

def delete_spending_sink(db: Session, spending_sink_id: UUID) -> None:
    db_spending_sink = db.get(SpendingSink, spending_sink_id)
    if db_spending_sink is None:
        raise exceptions.SpendingSinkDoesNotExistError
    db.delete(db_spending_sink)
    db.commit()
