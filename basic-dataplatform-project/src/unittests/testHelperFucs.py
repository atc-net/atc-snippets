from datetime import date, datetime, timezone
import string
import random
import uuid

def getRandomString() -> str:
    letters = string.ascii_letters
    return ''.join(random.choice(letters) for i in range(10))

def getRandomId() -> int:
    return random.getrandbits(63)

def getGuid() -> str:
    return str(uuid.uuid4())

def getDatetimeUtc(year, month=None, day=None, hour=0, minute=0, second=0, microsecond=0) -> datetime:
    return datetime(year=year,
        month=month,
        day=day,
        hour=hour,
        minute=minute,
        second=second,
        microsecond=microsecond,
        tzinfo=timezone.utc
    )

def getDatetimeNowUtc() -> datetime:
    return datetime.now(tz=timezone.utc)