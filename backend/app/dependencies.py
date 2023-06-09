from .database import engine

from .dao.funnels import FunnelDAO
from .dao.spendings import SpendingDAO

def get_funnel_dao():
    with engine.begin() as conn:
        yield FunnelDAO(conn, SpendingDAO(conn))

def get_spending_dao():
    with engine.begin() as conn:
        yield SpendingDAO(conn)
