import sqlalchemy as sa

from .config import DB_URL

print(f"Connecting to database at: {DB_URL}")

engine = sa.create_engine(DB_URL, echo=True)
metadata_obj = sa.MetaData()
