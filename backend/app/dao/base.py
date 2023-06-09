from sqlalchemy import Connection


class BaseDAO:
    _connection: Connection


    def __init__(self, connection: Connection):
        self._connection = connection

