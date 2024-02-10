from django.db.migrations.executor import MigrationExecutor
from django.db import connections, DEFAULT_DB_ALIAS
import sys
import time
import os
from django.core.management import execute_from_command_line


def is_database_synchronized(database):
    # connection = connections[database]
    # connection.prepare_database()
    # executor = MigrationExecutor(connection)
    # targets = executor.loader.graph.leaf_nodes()
    return execute_from_command_line(["manage.py", "migrate", "--check"])


def wait_for_migration():
    retries = 5
    elapse_secs = 10
    synchronized = is_database_synchronized(DEFAULT_DB_ALIAS)
    print(f"synchronized: {synchronized}")
    tries = 1
    while False and not synchronized and tries <= retries:
        print(f"not yet synchronzed, trying again in {elapse_secs}")
        time.sleep(elapse_secs)
        synchronized = is_database_synchronized(DEFAULT_DB_ALIAS)
    if not synchronized:
        raise Exception("Timeout waiting for migrations to be applied")


def migrate():
    return execute_from_command_line(["manage.py", "migrate"])


if __name__ == "__main__":
    if os.environ["NOMAD_ALLOC_INDEX"] == '0':
        migrate()
    else:
        wait_for_migration()
