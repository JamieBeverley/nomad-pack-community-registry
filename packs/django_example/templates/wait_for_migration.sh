#!/bin/sh

RETRIES=4
WAIT_SECONDS=5

check_migration() {
    ./manage.py migrate --check
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "Migrations are applied. Exiting..."
        exit 0
    else
        echo "Migrations not applied yet. Retrying in $WAIT_SECONDS seconds... ($i/$RETRIES)"
        return 1
    fi
}

wait_for_migrations(){
  for ((i=1; i<=$RETRIES; i++)); do
      check_migration
      if [ $? -ne 0 ]; then
          sleep $WAIT_SECONDS
      else
          exit 0
      fi
  done
}

apply_migrations(){
  ./manage.py migrate
}

if [ $NOMAD_ALLOC_INDEX -eq 0 ]; then
  apply_migrations
else
  wait_for_migrations
fi

echo "Migration checks failed $RETRIES times. Exiting..."
exit 1
