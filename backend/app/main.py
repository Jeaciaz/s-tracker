from fastapi import FastAPI

from .routers import funnels, spendings
from .database import metadata_obj, engine

def make_app() -> FastAPI:
    app = FastAPI()

    app.include_router(funnels.router)
    app.include_router(spendings.router)

    return app

app = make_app()

@app.get('/ping')
def ping():
    return 'pong'
