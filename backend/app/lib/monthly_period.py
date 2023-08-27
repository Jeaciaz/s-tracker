from datetime import datetime
from calendar import monthrange
import math


def ms_timestamp(dt: datetime):
    return math.ceil(dt.timestamp() * 1000)

def get_current_period_start(dt: datetime = datetime.now()):
    dt = dt.replace(month=dt.month - 1 if dt.day < 5 else dt.month, day=5)
    return ms_timestamp(dt)

def get_current_period_remaining_days(dt: datetime = datetime.now()):
    next_period_start = dt.replace(month=dt.month + 1 if dt.day >= 5 else dt.month, day=5)
    return (next_period_start - dt).days

def get_current_period_length(dt: datetime = datetime.now()):
    return monthrange(dt.year, dt.month if dt.day >= 5 else dt.replace(month=dt.month-1).month)[1]
