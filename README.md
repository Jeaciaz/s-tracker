# STracker
This is a personal project for me and my family to track expenses and plan our budget with some personal and shared spending categories (I call them funnels here).

## Overview
The following video is taken on a live version of the app, the PWA hosted at a private-owned domain. Since the SSL certificate is self-signed, it's not really open to the general public, but I have arranged access to my family and a few of my friends. 

https://github.com/Jeaciaz/s-tracker/assets/6773331/8da479a6-bcdf-475d-8cf0-c4ac21bdc8f1


The app's workflow is pretty intuitive, here it is in detail:
- To register, a user adds a secret key to something like Google Authenticator (the black screen in the recording), which is also stored on the server and is later used to authenticate the user in case a logout happens. This isn't a common case, though - after the registration a pair of Json Web Tokens is created, the short-lived one is used for communicating with the server, and the long-lived one renews both tokens when the short-lived one expires, if not too much time passed. There is also a blacklisting system that ensures that for each user, only one device may be active at a time, to protect against possible MITM attacks. **TL;DR** - the app uses a passwordless One-Time-Password system with automatically renewed JWTs, so if the user is active they never need to log in again.
- On the main screen, the user sees an overview of their budget. They can see how much is remaining for the month in the current period for each funnel, and the pre-calculated value of the money they can spend today in order to fit in the budget. They can also input their new spendings there, which is done in two clicks apart from actually entering the amount, all to minimize the UI friction. Lastly, there is the list of last savings, with an option to delete each of them in case of a typo or a refund.
- Each user gets two pre-generated funnels when they register, however it's easy to customize the amount of funnels, and the parameters of each funnel, including: emoji, name, color and monthly limit. They can be freely created, edited and deleted without the need to adjust existing spendings - everything will be automatically recalculated if you decide to change your budget mid-period. The user however loses information about all spendings in a category if they decide to delete it.

## Deploy the app
Deployment is simple. First, you need to set up environment variables:

```cp backend/.env.example backend/.env && vi backend/.env```

They are described further on.
Then, it is as simple as running:
```docker compose build && docker compose up -d```

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
- Docker
- REST
