"""create funnels table

Revision ID: fb0a5855532d
Revises: 
Create Date: 2023-06-03 19:05:24.404546

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'fb0a5855532d'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('funnels',
    sa.Column('id', sa.String(), nullable=False),
    sa.Column('name', sa.String(), nullable=True),
    sa.Column('limit', sa.Float(), nullable=True),
    sa.Column('color', sa.String(), nullable=True),
    sa.Column('emoji', sa.String(length=1), nullable=True),
    sa.PrimaryKeyConstraint('id')
    )
    # ### end Alembic commands ###


def downgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_table('funnels')
    # ### end Alembic commands ###
