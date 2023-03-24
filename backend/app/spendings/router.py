from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, status, Depends, Response
from sqlalchemy.orm import Session

from ..dependencies import get_db
from . import schemas, models, exceptions

router = APIRouter(
    prefix="/spendings",
    tags=["spendings"],
)


@router.get("/",
            summary="Get all spendings made since date_from",
            status_code=status.HTTP_200_OK,
            response_model=list[schemas.Spending])
def spendings_list(date_from: datetime | None = None, db: Session = Depends(get_db)):
    """
    Get all spendings made since date_from. If not provided, all spendings are retrieved.
    """
    return models.get_spendings(db, date_from=date_from)


@router.post("/{spending_sink_id}",
             summary="Create a spending",
             status_code=status.HTTP_201_CREATED,
             response_model=schemas.Spending)
def create_spending(spending_sink_id: UUID, spending: schemas.SpendingCreate, db: Session = Depends(get_db)):
    return models.create_spending(db=db, spending=spending, spending_sink_id=spending_sink_id)


@router.put("/{spending_id}",
            summary="Update something about existing spending",
            status_code=status.HTTP_200_OK,
            response_model=None)
def update_spending(spending_id: UUID, spending: schemas.SpendingCreate, db: Session = Depends(get_db)):
    return models.update_spending(db=db, spending=spending, spending_id=spending_id)


@router.delete("/{spending_id}",
               summary="Delete a spending",
               status_code=status.HTTP_200_OK,
               response_model=None)
def delete_spenging(response: Response, spending_id: UUID, db: Session = Depends(get_db)):
    try:
        return models.remove_spending(db=db, spending_id=spending_id)
    except exceptions.SpendingDoesNotExistError:
        response.status_code = status.HTTP_404_NOT_FOUND
