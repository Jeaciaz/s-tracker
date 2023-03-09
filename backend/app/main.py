from fastapi import FastAPI

from .spending import router as spending_router
from .category import router as categories_router
from .database import Base, engine

Base.metadata.create_all(bind=engine)

app = FastAPI()

app.include_router(categories_router.router)
app.include_router(spending_router.router)

@app.get('/ping')
def ping():
    return 'pong'
