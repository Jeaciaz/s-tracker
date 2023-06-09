from datetime import datetime
import math


def ms_timestamp(dt: datetime):
    return math.ceil(dt.timestamp() * 1000)

def get_current_period_start():
    dt = datetime.now()
    dt = dt.replace(month=dt.month - 1 if dt.day < 5 else dt.month, day=5)
    return ms_timestamp(dt)
    
