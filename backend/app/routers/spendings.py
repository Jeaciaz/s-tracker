from pydantic import UUID4
from fastapi import APIRouter, status, HTTPException

from ..dependencies import DepSpendingDAO, VoidDepUserAuth, DepUserAuth
from ..exceptions import SpendingDoesNotExistException
from ..dto.spendings import *

router = APIRouter(prefix="/spending", tags=["spending"])


@router.get(
    "/",
    summary="Get a list of all spendings between optional timestamp bounds",
    status_code=status.HTTP_200_OK,
    response_model=list[SpendingPublic],
)
def get_spendings(
    spending_dao: DepSpendingDAO,
    user: DepUserAuth,
    timestamp_from: int | None = None,
    timestamp_to: int | None = None,
):
    return spending_dao.get_all(
        username=user.username, timestamp_from=timestamp_from, timestamp_to=timestamp_to
    )


@router.post(
    "/",
    summary="Create a spending",
    status_code=status.HTTP_201_CREATED,
    response_model=UUID4,
    dependencies=[VoidDepUserAuth],
)
def post_spending(spending: SpendingCreate, spending_dao: DepSpendingDAO):
    return spending_dao.create(spending)


@router.put(
    "/{spending_id}",
    summary="Update a spending",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[VoidDepUserAuth],
)
def put_spending(
    spending_id: UUID4, spending: SpendingCreate, spending_dao: DepSpendingDAO
):
    try:
        return spending_dao.update(spending_id, spending)
    except SpendingDoesNotExistException:
        raise HTTPException(status_code=404, detail="Spending does not exist")


@router.delete(
    "/{spending_id}",
    summary="Delete a spending",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[VoidDepUserAuth],
)
def delete_spending(spending_id: UUID4, spending_dao: DepSpendingDAO):
    try:
        return spending_dao.delete(spending_id)
    except SpendingDoesNotExistException:
        raise HTTPException(status_code=404, detail="Spending does not exist")
