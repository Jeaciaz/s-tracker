from pydantic import UUID4
from fastapi import Depends, APIRouter, status, Response

from ..dependencies import get_spending_dao
from ..exceptions import SpendingDoesNotExistException
from ..dto.spendings import *
from ..dao.spendings import SpendingDAO

router = APIRouter(
    prefix="/spending",
    tags=["spending"]
)

@router.get('/',
            summary="Get a list of all spendings between optional timestamp bounds",
            status_code=status.HTTP_200_OK,
            response_model=list[SpendingPublic])
def get_spendings(spending_dao: SpendingDAO = Depends(get_spending_dao), timestamp_from: int | None = None, timestamp_to: int | None = None):
    return spending_dao.get_all(timestamp_from, timestamp_to)


@router.post('/',
             summary="Create a spending",
             status_code=status.HTTP_201_CREATED,
             response_model=UUID4)
def post_spending(spending: SpendingCreate, spending_dao: SpendingDAO = Depends(get_spending_dao)):
    return spending_dao.create(spending)


@router.put('/{spending_id}',
            summary="Update a spending",
            status_code=status.HTTP_204_NO_CONTENT)
def put_spending(response: Response, spending_id: UUID4, spending: SpendingCreate, spending_dao: SpendingDAO = Depends(get_spending_dao)):
    try:
        return spending_dao.update(spending_id, spending)
    except SpendingDoesNotExistException:
        response.status_code = status.HTTP_404_NOT_FOUND


@router.delete('/{spending_id}',
               summary="Delete a spending",
               status_code=status.HTTP_204_NO_CONTENT)
def delete_spending(response: Response, spending_id: UUID4, spending_dao: SpendingDAO = Depends(get_spending_dao)):
    try:
        return spending_dao.delete(spending_id)
    except SpendingDoesNotExistException:
        response.status_code = status.HTTP_404_NOT_FOUND
