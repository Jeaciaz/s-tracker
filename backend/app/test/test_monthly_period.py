from datetime import datetime
from ..lib.monthly_period import *


def test_period_start():
    assert get_current_period_start(
        datetime(year=2023, month=9, day=20)
    ) == ms_timestamp(datetime(year=2023, month=9, day=5))
    assert get_current_period_start(
        datetime(year=2023, month=9, day=4)
    ) == ms_timestamp(datetime(year=2023, month=8, day=5))
    assert get_current_period_start(
        datetime(year=2023, month=9, day=5)
    ) == ms_timestamp(datetime(year=2023, month=9, day=5))


def test_period_length():
    assert get_current_period_length(datetime(year=2023, month=1, day=20)) == 31
    assert get_current_period_length(datetime(year=2023, month=2, day=20)) == 28
    assert get_current_period_length(datetime(year=2024, month=2, day=20)) == 29
    assert get_current_period_length(datetime(year=2023, month=4, day=20)) == 30


def test_period_remaining():
    assert get_current_period_remaining_days(datetime(year=2023, month=9, day=20)) == 14
    assert get_current_period_remaining_days(datetime(year=2023, month=9, day=5)) == 29
    assert get_current_period_remaining_days(datetime(year=2023, month=9, day=4)) == 0
