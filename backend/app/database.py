from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase

SQLALCHEMY_DATABASE_URL = 'sqlite:///../sqlite.db'

engine = create_engine(SQLALCHEMY_DATABASE_URL, echo=True)
SessionLocal = sessionmaker(autoflush=False)
SessionLocal.configure(bind=engine)

class Base(DeclarativeBase):
    ...
