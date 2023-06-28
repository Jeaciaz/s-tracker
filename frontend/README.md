# XTracker frontend

## Setup

Using docker compose, this should mostly be automatic. However, due to PWAs having to use SSL, it's required to have the certificates on the server. So before doing the docker compose, you should run `certbot` on the server:
`certbot certonly -d mydomain.com`

In my case, the domain is jeaciaz.site. When using a different domain, update volume in docker-compose accordingly. Other changes are (hopefully) not needed.
