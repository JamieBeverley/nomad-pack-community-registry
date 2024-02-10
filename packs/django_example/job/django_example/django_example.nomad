job "django_example" {

  datacenters = ["*"]
  type        = "service"

  group "app" {
    count = 5

    network {
      mode = "host"
      port "http" {
        to = 8000
      }
    }


    service {
      name     = "webapp"
      tags     = []
      provider = "nomad"
      port     = "http"


      check = {

        interval = "10s"
        path     = "/"
        timeout  = "5s"
        type     = "http"
      }

    }


    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    task "migrate" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      env {

        DEBUG             = "off"
        POSTGRES_HOST     = "10.0.0.225"
        POSTGRES_NAME     = "testdb"
        POSTGRES_PASSWORD = "password"
        POSTGRES_PORT     = "5432"
        POSTGRES_USER     = "postgres"
        test              = "1234"
      }

      config {
        image   = "localhost:5000/djangotesting:3"
        command = "/django_migration/nomad_wait_for_migration.sh"
        mount {
          type   = "bind"
          source = "local"
          target = "/django_migration"
        }
      }

      template {
        destination = "local/nomad_wait_for_migration.sh"
        change_mode = "noop"
        perms       = "0755"
        data        = <<EOF
#!/bin/bash

RETRIES=5
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
  echo "Migrations not applied after $RETRIES retries. Exiting..."
  exit 1
}

apply_migrations(){
  ./manage.py migrate
  exit 0
}

echo "NOMAD_ALLOC_INDEX: $NOMAD_ALLOC_INDEX"
if [ $NOMAD_ALLOC_INDEX -eq 0 ]; then
  echo "Index is 0. Applying migrations..."
  apply_migrations
else
  echo "Index is not 0. Waiting for leader alloc to apply migrations..."
  wait_for_migrations
fi
EOF
      }
    }

    task "server" {
      driver = "docker"

      env {

        DEBUG             = "off"
        POSTGRES_HOST     = "10.0.0.225"
        POSTGRES_NAME     = "testdb"
        POSTGRES_PASSWORD = "password"
        POSTGRES_PORT     = "5432"
        POSTGRES_USER     = "postgres"
        test              = "1234"
      }

      config {
        image = "localhost:5000/djangotesting:3"
        ports = ["http"]
      }


      resources {
        cpu    = 100
        memory = 300
      }
    }
  }
}
