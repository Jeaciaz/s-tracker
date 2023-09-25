FROM python:3.11

WORKDIR /backend

COPY ./requirements.txt /backend/requirements.txt

RUN python3 -m pip install --no-cache-dir --upgrade -r requirements.txt

COPY . /backend

RUN ["chmod", "+x", "/backend/docker-entry.sh"]
