from datetime import datetime
from calendar import monthrange
import math

PERIOD_BREAKPOINT = 15


def clamp_month(month: int) -> int:
    if month % 12 == 0:
        return 12
    return month % 12


def ms_timestamp(dt: datetime):
    return math.ceil(dt.timestamp() * 1000)


def get_current_period_start(dt: datetime = datetime.now()):
    dt = dt.replace(
        month=clamp_month(dt.month - 1 if dt.day < PERIOD_BREAKPOINT else dt.month),
        day=PERIOD_BREAKPOINT,
    )
    return ms_timestamp(dt)


def get_current_period_remaining_days(dt: datetime = datetime.now()):
    next_period_start = dt.replace(
        month=clamp_month(
            dt.month + 1 if dt.day >= PERIOD_BREAKPOINT else dt.month,
        ),
        day=PERIOD_BREAKPOINT,
    )
    return (next_period_start - dt).days - 1


def get_current_period_length(dt: datetime = datetime.now()):
    return monthrange(
        dt.year,
        clamp_month(
            dt.month
            if dt.day >= PERIOD_BREAKPOINT
            else dt.replace(month=clamp_month(dt.month - 1)).month
        ),
    )[1]
