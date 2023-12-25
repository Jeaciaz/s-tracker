from datetime import datetime
from calendar import monthrange
from typing import Tuple
import math

PERIOD_BREAKPOINT = 15


def clamp_month(month: int, year: int) -> Tuple[int, int]:
    """Returns new month and a delta for the year"""
    if month % 12 == 0:
        return 12, year + 1
    return month % 12, year + math.floor(month / 12)


def ms_timestamp(dt: datetime):
    return math.ceil(dt.timestamp() * 1000)


def get_current_period_start(dt: datetime = datetime.now()):
    new_month, new_year = clamp_month(
        dt.month - 1 if dt.day < PERIOD_BREAKPOINT else dt.month, dt.year
    )
    dt = dt.replace(
        year=new_year,
        month=new_month,
        day=PERIOD_BREAKPOINT,
    )
    return ms_timestamp(dt)


def get_current_period_remaining_days(dt: datetime = datetime.now()):
    new_month, new_year = clamp_month(
        dt.month + 1 if dt.day >= PERIOD_BREAKPOINT else dt.month, dt.year
    )
    next_period_start = dt.replace(
        year=new_year,
        month=new_month,
        day=PERIOD_BREAKPOINT,
    )
    return (next_period_start - dt).days - 1


def get_current_period_length(dt: datetime = datetime.now()):
    new_month, new_year = clamp_month(
        dt.month if dt.day >= PERIOD_BREAKPOINT else dt.month - 1, dt.year
    )
    return monthrange(new_year, new_month)[1]
