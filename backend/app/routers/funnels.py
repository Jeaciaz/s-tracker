from uuid import UUID

from fastapi import APIRouter, status, Depends, Response
from sqlalchemy.orm import Session
import pydantic

from ..dependencies import get_funnel_dao
from ..exceptions import FunnelDoesNotExistException
from ..dto.funnels import *
from ..dao.funnels import FunnelDAO

router = APIRouter(
    prefix="/funnel",
    tags=["funnel"],
)


@router.get("/",
            summary="Get a list of all funnels",
            status_code=status.HTTP_200_OK,
            response_model=list[FunnelPublic])
def funnels_list(funnel_dao: FunnelDAO = Depends(get_funnel_dao)):
    return funnel_dao.get_all()


@router.post("/",
             summary="Create a new funnel",
             status_code=status.HTTP_201_CREATED,
             response_model=pydantic.UUID4)
def create_funnel(funnel: FunnelCreate, funnel_dao: FunnelDAO = Depends(get_funnel_dao)):
    return funnel_dao.create(funnel)


@router.put("/{funnel_id}",
            summary="Update an existing funnel",
            status_code=status.HTTP_204_NO_CONTENT)
def update_funnel(response: Response, funnel_id: UUID, funnel: FunnelCreate, funnel_dao: FunnelDAO = Depends(get_funnel_dao)):
    try:
        funnel_dao.update(funnel_id, funnel)
    except FunnelDoesNotExistException:
        response.status_code = status.HTTP_404_NOT_FOUND


@router.delete("/{funnel_id}",
               summary="Delete a funnel",
               status_code=status.HTTP_204_NO_CONTENT)
def delete_funnel(response: Response, funnel_id: UUID, funnel_dao: FunnelDAO = Depends(get_funnel_dao)):
    try:
        funnel_dao.delete(funnel_id)
    except FunnelDoesNotExistException:
        response.status_code = status.HTTP_404_NOT_FOUND

