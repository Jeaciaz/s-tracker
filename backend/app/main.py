from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routers import funnels, spendings
from .database import metadata_obj, engine

allowed_origins = [
    "*"
]

def make_app() -> FastAPI:
    app = FastAPI()

    app.include_router(funnels.router)
    app.include_router(spendings.router)

    app.add_middleware(
        CORSMiddleware, 
        allow_origins=allowed_origins, 
        allow_credentials=True, 
        allow_methods=["*"], 
        allow_headers=["*"]
    )

    return app

app = make_app()

@app.get('/ping')
def ping():
    return 'pong'
