#!/bin/bash

mkdir -p /db
touch /db/sqlite.db

alembic upgrade head

uvicorn app.main:app --host 0.0.0.0 --port 8080
