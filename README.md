# STracker
This is a personal project for me and my family to track expenses and plan our budget with some personal and shared spending categories (I call them funnels here).

## Deploy the app
Deployment is simple. First, you need to set up environment variables:

```cp backend/.env.example backend/.env && vi backend/.env```

They are described further on.
Then, it is as simple as running:
```docker compose build && docker compose up -d```

Running the development version is trickier, and will be described later.

## ENV Variables
`DB_URL` - the string that indicates where the DB will be. See https://docs.sqlalchemy.org/en/20/core/engines.html#sqlalchemy.create_engine

`JWT_SECRET` - a secret key for generating JWTs for auth

## Dev build
To run frontend:
```cd frontend && npm run dev```

To run backend:
```cd backend && sh dev.sh```

## Run tests
After doing `cd backend`:

```pytest .```

## Tech stack
This project uses:
- Python
- FastAPI
- SqlAlchemy Core
- SQLite
- Pytest
- Elm
