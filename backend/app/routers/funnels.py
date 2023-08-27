from uuid import UUID

from fastapi import APIRouter, status, HTTPException
import pydantic

from ..dependencies import DepFunnelDAO
from ..exceptions import FunnelDoesNotExistException
from ..dto.funnels import *

router = APIRouter(
    prefix="/funnel",
    tags=["funnel"],
)

@router.get("/",
            summary="Get a list of all funnels",
            status_code=status.HTTP_200_OK,
            response_model=list[FunnelPublic])
def funnels_list(funnel_dao: DepFunnelDAO):
    return funnel_dao.get_all()


@router.post("/",
             summary="Create a new funnel",
             status_code=status.HTTP_201_CREATED,
             response_model=pydantic.UUID4)
def create_funnel(funnel: FunnelCreate, funnel_dao: DepFunnelDAO):
    return funnel_dao.create(funnel)


@router.put("/{funnel_id}",
            summary="Update an existing funnel",
            status_code=status.HTTP_204_NO_CONTENT)
def update_funnel(funnel_id: UUID, funnel: FunnelCreate, funnel_dao: DepFunnelDAO):
    try:
        funnel_dao.update(funnel_id, funnel)
    except FunnelDoesNotExistException:
        raise HTTPException(status_code=404, detail="Funnel does not exist")


@router.delete("/{funnel_id}",
               summary="Delete a funnel",
               status_code=status.HTTP_204_NO_CONTENT)
def delete_funnel(funnel_id: UUID, funnel_dao: DepFunnelDAO):
    try:
        funnel_dao.delete(funnel_id)
    except FunnelDoesNotExistException:
        raise HTTPException(status_code=404, detail="Funnel does not exist")

