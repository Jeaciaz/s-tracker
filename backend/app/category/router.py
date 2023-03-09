from fastapi import APIRouter, status, Depends, Response
from sqlalchemy.orm import Session

from ..dependencies import get_db
from . import schemas, models, exceptions

router = APIRouter(
    prefix="/categories",
    tags=["categories"]
)


@router.get("/",
            summary="Get a list of all categories",
            status_code=status.HTTP_200_OK,
            response_model=list[schemas.Category])
def categories_list(db: Session = Depends(get_db)):
    return models.get_categories(db=db)


@router.post("/",
             summary="Create a new category",
             status_code=status.HTTP_201_CREATED,
             response_model=schemas.Category)
def create_category(category: schemas.CategoryCreate, db: Session = Depends(get_db)):
    return models.create_category(db=db, category=category)


@router.put("/{category_id}",
            summary="Update an existing category",
            status_code=status.HTTP_200_OK,
            response_model=schemas.Category)
def update_category(category_id: int, category: schemas.CategoryCreate, db: Session = Depends(get_db)):
    return models.update_category(db=db, category_id=category_id, category=category)


@router.delete("/{category_id}",
               summary="Delete a category",
               status_code=status.HTTP_200_OK,
               response_model=None)
def delete_category(response: Response, category_id: int, db: Session = Depends(get_db)):
    try:
        return models.delete_category(db=db, category_id=category_id)
    except exceptions.CategoryDoesNotExistError:
        response.status_code = status.HTTP_404_NOT_FOUND
