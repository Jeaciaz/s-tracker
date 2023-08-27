"""create users table

Revision ID: 49e891c30695
Revises: 799ef2f6fb83
Create Date: 2023-08-21 18:52:35.465713

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '49e891c30695'
down_revision = '799ef2f6fb83'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('users',
    sa.Column('username', sa.String(), nullable=False),
    sa.Column('password', sa.String(), nullable=False),
    sa.PrimaryKeyConstraint('username')
    )
    op.execute("INSERT INTO users VALUES ('root', 'root')")
    op.add_column('funnels', sa.Column('user_name', sa.String(), nullable=False, server_default='root'))

    with op.batch_alter_table('funnels') as batch_op:
        batch_op.create_foreign_key('fk_funnel_user', 'users', ['user_name'], ['username'])
    # ### end Alembic commands ###


def downgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('funnels') as batch_op:
        batch_op.drop_constraint('fk_funnel_user', type_='foreignkey')
    op.drop_column('funnels', 'user_name')
    op.drop_table('users')
    # ### end Alembic commands ###