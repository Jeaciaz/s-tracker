from fastapi import APIRouter, status, Depends, Response
from sqlalchemy.orm import Session
from uuid import UUID

from ..dependencies import get_db
from . import schemas, models, exceptions

router = APIRouter(
    prefix="/spending-sinks",
    tags=["spending-sinks"],
)


@router.get("/",
            summary="Get a list of all spending sinks",
            status_code=status.HTTP_200_OK,
            response_model=list[schemas.SpendingSink])
def spending_sinks_list(db: Session = Depends(get_db)):
    return models.get_spending_sinks(db=db)


@router.post("/",
             summary="Create a new spending sink",
             status_code=status.HTTP_201_CREATED,
             response_model=schemas.SpendingSink)
def create_spending_sink(spending_sink: schemas.SpendingSinkCreate, db: Session = Depends(get_db)):
    return models.create_spending_sink(db=db, spending_sink=spending_sink)


@router.put("/{spending_sink_id}",
            summary="Update an existing spending sink",
            status_code=status.HTTP_200_OK,
            response_model=None)
def update_spending_sink(spending_sink_id: UUID, spending_sink: schemas.SpendingSinkCreate, db: Session = Depends(get_db)):
    return models.update_spending_sink(db=db, spending_sink_id=spending_sink_id, spending_sink=spending_sink)


@router.delete("/{spending_sink_id}",
               summary="Delete a spending sink",
               status_code=status.HTTP_200_OK,
               response_model=None)
def delete_spending_sink(response: Response, spending_sink_id: UUID, db: Session = Depends(get_db)):
    try:
        return models.delete_spending_sink(db=db, spending_sink_id=spending_sink_id)
    except exceptions.SpendingSinkDoesNotExistError:
        response.status_code = status.HTTP_404_NOT_FOUND
