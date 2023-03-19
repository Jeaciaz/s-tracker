from fastapi import FastAPI

from .spendings import router as spendings_router
from .spending_groups import router as spending_groups_router
from .database import Base, engine

Base.metadata.create_all(bind=engine)

app = FastAPI()

app.include_router(spending_groups_router.router)
app.include_router(spendings_router.router)

@app.get('/ping')
def ping():
    return 'pong'
