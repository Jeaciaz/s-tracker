import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
import sqlalchemy as sa
from sqlalchemy.pool import StaticPool
import pyotp

from datetime import datetime, timedelta
from uuid import uuid4

from .database import metadata_obj
from .lib.monthly_period import ms_timestamp
from .main import make_app
from .dao.funnels import *
from .dto.funnels import *
from .dependencies import *
from .dao.spendings import *
from .dto.spendings import *
from .dao.users import *
from .dto.users import *
from .test.dependency_overrider import DependencyOverrider

SQLALCHEMY_TEST_URL = "sqlite://"
TEST_OTP_SECRET = pyotp.random_base32()
TEST_USERNAME = "test"

engine = sa.create_engine(
    SQLALCHEMY_TEST_URL, connect_args={"check_same_thread": False}, poolclass=StaticPool
)

now = datetime.now()


def insert_test_data(conn: sa.Connection):
    conn.execute(
        sa.insert(users_table).values(
            {"username": TEST_USERNAME, "otp_secret": TEST_OTP_SECRET}
        )
    )
    for ss in range(3):
        ss_id = uuid4()
        conn.execute(
            sa.insert(funnels_table).values(
                {
                    "id": str(ss_id),
                    "name": f"Test #{ss}",
                    "limit": 20000,
                    "color": "rgb(235,172,12)",
                    "emoji": "🎀",
                    "user_name": "test",
                }
            )
        )
        for s in range(3):
            s_id = uuid4()
            conn.execute(
                sa.insert(spendings_table).values(
                    {
                        "id": str(s_id),
                        "amount": 50 * (s + 2),
                        "timestamp": ms_timestamp(datetime.now()),
                        "funnel_id": str(ss_id),
                    }
                )
            )
    conn.commit()


@pytest.fixture
def user_data():
    yield {"username": TEST_USERNAME, "otp_secret": TEST_OTP_SECRET}


@pytest.fixture
def app():
    """Create a fresh DB for each test case"""
    metadata_obj.create_all(bind=engine)
    _app = make_app()
    yield _app
    metadata_obj.drop_all(bind=engine)


@pytest.fixture
def db_connection():
    """Create a fresh SQLAlchemy connection for each test case. The transaction is rolled back after each test."""
    with engine.connect() as conn:
        insert_test_data(conn)
        yield conn


@pytest.fixture(scope="function")
def fake_auth(app: FastAPI):
    def get_test_user_auth():
        try:
            yield UserJwtPayload(
                username="test",
                exp=round((now + timedelta(minutes=5)).timestamp()),
                iat=round(now.timestamp()),
                type="access",
            )
        finally:
            pass

    with DependencyOverrider(
        app, overrides={get_user_auth: get_test_user_auth}
    ) as overrider:
        yield overrider


@pytest.fixture
def client(app: FastAPI, db_connection: sa.Connection):
    def get_test_funnel_dao():
        try:
            yield FunnelDAO(db_connection, SpendingDAO(db_connection))
        finally:
            pass

    def get_test_spending_dao():
        try:
            yield SpendingDAO(db_connection)
        finally:
            pass

    def get_test_user_dao():
        try:
            yield UsersDAO(db_connection)
        finally:
            pass

    app.dependency_overrides[get_funnel_dao] = get_test_funnel_dao
    app.dependency_overrides[get_spending_dao] = get_test_spending_dao
    app.dependency_overrides[get_user_dao] = get_test_user_dao

    with TestClient(app) as client:
        yield client
