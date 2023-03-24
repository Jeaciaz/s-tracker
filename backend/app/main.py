from fastapi import FastAPI

from .spendings import router as spendings_router
from .spending_sinks import router as spending_sinks_router
from .database import Base, engine

Base.metadata.create_all(bind=engine)

def make_app():
    app = FastAPI()

    app.include_router(spending_sinks_router.router)
    app.include_router(spendings_router.router)

    return app

app = make_app()

@app.get('/ping')
def ping():
    return 'pong'
