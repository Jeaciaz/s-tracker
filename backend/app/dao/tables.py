import sqlalchemy as sa

from ..database import metadata_obj


users_table_name = "users"

users_table = sa.Table(
    users_table_name,
    metadata_obj,
    sa.Column("username", sa.String, primary_key=True),
    sa.Column("otp_secret", sa.String, nullable=False),
)


funnels_table_name = "funnels"

funnels_table = sa.Table(
    funnels_table_name,
    metadata_obj,
    sa.Column("id", sa.String, primary_key=True),
    sa.Column("name", sa.String),
    sa.Column("limit", sa.Float),
    sa.Column("color", sa.String),
    sa.Column("emoji", sa.String(1)),
    sa.Column(
        "user_name", sa.String, sa.ForeignKey(users_table.c.username), nullable=False
    ),
)


spendings_table_name = "spendings"

spendings_table = sa.Table(
    spendings_table_name,
    metadata_obj,
    sa.Column("id", sa.String, primary_key=True),
    sa.Column("amount", sa.Float),
    sa.Column("timestamp", sa.Integer),
    sa.Column(
        "funnel_id", sa.String, sa.ForeignKey(funnels_table.c.id), nullable=False
    ),
)


jwt_blacklist_table_name = "jwt_blacklist"

jwt_blacklist_table = sa.Table(
    jwt_blacklist_table_name,
    metadata_obj,
    sa.Column(
        "username",
        sa.String,
        sa.ForeignKey(users_table.c.username),
        nullable=False,
        primary_key=True,
    ),
    sa.Column("iat_until", sa.Integer),
)
