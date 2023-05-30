import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool

from datetime import datetime
from uuid import uuid4

from .database import Base
from .dependencies import get_db
from .main import make_app
from . import spending_sinks, spendings

SQLALCHEMY_TEST_URL = 'sqlite://'

engine = create_engine(
    SQLALCHEMY_TEST_URL, connect_args={"check_same_thread": False}, poolclass=StaticPool
)
TestingSessionLocal = sessionmaker(autoflush=False, bind=engine)
now = datetime.now()


def insert_test_data(db: Session):
    for ss in range(3):
        ss_id = uuid4()
        db.add(spending_sinks.models.SpendingSink(
            id=ss_id,
            name=f'Test #{ss}',
            limit=20000,
            color='rgb(235, 172, 12)',
            emoji='🎀',
        ))

        for s in range(3):
            db.add(spendings.models.Spending(
                id=uuid4(),
                amount=(s+1)*50,
                datetime=now,
                spending_sink_id=ss_id
            ))
    db.commit()


@pytest.fixture
def app():
    """Create a fresh DB for each test case"""
    Base.metadata.create_all(bind=engine)
    _app = make_app()
    yield _app
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def db_session():
    """Create a fresh SQLAlchemy session for each test case. The transaction is rolled back after each test."""
    connection = engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)
    insert_test_data(session)
    yield session
    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(app: FastAPI, db_session: Session):
    def get_test_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = get_test_db

    with TestClient(app) as client:
        yield client
