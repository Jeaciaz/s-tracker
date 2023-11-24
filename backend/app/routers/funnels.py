from uuid import UUID

from fastapi import APIRouter, status, HTTPException
import pydantic

from ..dependencies import DepFunnelDAO, DepUserAuth, VoidDepUserAuth
from ..exceptions import FunnelDoesNotExistException
from ..dto.funnels import *

router = APIRouter(
    prefix="/funnel",
    tags=["funnel"],
)


@router.get(
    "/",
    summary="Get a list of all funnels",
    status_code=status.HTTP_200_OK,
    response_model=list[FunnelPublic],
)
def funnels_list(funnel_dao: DepFunnelDAO, user: DepUserAuth):
    return funnel_dao.get_all(user.username)


@router.get(
    "/{funnel_id}",
    summary="Get a single funnel",
    status_code=200,
    response_model=FunnelPublic,
)
def get_funnel(funnel_id: UUID, funnel_dao: DepFunnelDAO, user: DepUserAuth):
    result = funnel_dao.get(funnel_id, user.username)
    if result is None:
        raise HTTPException(status_code=404, detail="Funnel not found")
    return result


@router.post(
    "/",
    summary="Create a new funnel",
    status_code=status.HTTP_201_CREATED,
    response_model=pydantic.UUID4,
)
def create_funnel(
    funnel: FunnelCreateBody, funnel_dao: DepFunnelDAO, user: DepUserAuth
):
    return funnel_dao.create(FunnelCreate(**funnel.dict(), user_name=user.username))


@router.put(
    "/{funnel_id}",
    summary="Update an existing funnel",
    status_code=status.HTTP_204_NO_CONTENT,
)
def update_funnel(
    funnel_id: UUID,
    funnel: FunnelCreateBody,
    funnel_dao: DepFunnelDAO,
    user: DepUserAuth,
):
    try:
        funnel_dao.update(
            funnel_id, FunnelCreate(**funnel.dict(), user_name=user.username)
        )
    except FunnelDoesNotExistException:
        raise HTTPException(status_code=404, detail="Funnel does not exist")


@router.delete(
    "/{funnel_id}",
    summary="Delete a funnel",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[VoidDepUserAuth],
)
def delete_funnel(funnel_id: UUID, funnel_dao: DepFunnelDAO):
    try:
        funnel_dao.delete(funnel_id)
    except FunnelDoesNotExistException:
        raise HTTPException(status_code=404, detail="Funnel does not exist")
