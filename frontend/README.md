# XTracker frontend

## Setup

Using docker compose, this should mostly be automatic. However, due to PWAs having to use SSL, it's required to have the certificates on the server. So before doing the docker compose, you should generate a certificate (even self-signed) and place it and the key under `nginx/ssl/server.crt` and `nginx/ssl/server.key` relative to this file correspondingly. 

Other changes are (hopefully) not needed.
