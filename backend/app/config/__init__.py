import os

from dotenv import load_dotenv

load_dotenv()

DB_URL: str = os.getenv('DB_URL') or './sqlite.db'
JWT_SECRET: str = os.getenv('JWT_SECRET') or 'secret' # TODO this should be automatically generated and re-generated every month or so
