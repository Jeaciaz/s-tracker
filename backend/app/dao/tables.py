import sqlalchemy as sa

from ..database import metadata_obj


funnels_table_name = "funnels"

funnels_table = sa.Table(
    funnels_table_name,
    metadata_obj,
    sa.Column("id", sa.String, primary_key=True),
    sa.Column("name", sa.String),
    sa.Column("limit", sa.Float),
    sa.Column("color", sa.String),
    sa.Column("emoji", sa.String(1)),
)


spendings_table_name = "spendings"

spendings_table = sa.Table(
    spendings_table_name,
    metadata_obj,
    sa.Column('id', sa.String, primary_key=True),
    sa.Column('amount', sa.Float),
    sa.Column('timestamp', sa.Integer),

    sa.Column('funnel_id', sa.String, sa.ForeignKey(funnels_table.c.id), nullable=False)
)

