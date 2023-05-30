# XTracker
This is a personal project for me and my family to track expenses and plan our budget with some personal and shared spending categories (I call them sinks here).

## Set up & launch backend
Enter backend directory:

```cd backend```

Install requirements (probably in a virtual environment):

```pip install -r requirements.txt```

Run the server:

```uvicorn app.main:app --reload```

**TODO**: do this using Docker.

## Run tests
After doing `cd backend`:

```pytest .```

## Tech stack
This project uses:
- Python
- FastAPI
- SqlAlchemy/ORM
- SQLite
- Pytest
