from datetime import datetime
from calendar import monthrange
import math


def ms_timestamp(dt: datetime):
    return math.ceil(dt.timestamp() * 1000)

def get_current_period_start():
    dt = datetime.now()
    dt = dt.replace(month=dt.month - 1 if dt.day < 5 else dt.month, day=5)
    return ms_timestamp(dt)

def get_current_period_remaining_days():
    now = datetime.now()
    next_period_start = now.replace(month=now.month + 1 if now.day >= 5 else now.month, day=5)
    return (next_period_start - now).days

def get_current_period_length():
    now = datetime.now()
    return monthrange(now.year, now.month if now.day >= 5 else now.replace(month=now.month-1).month)[1]
