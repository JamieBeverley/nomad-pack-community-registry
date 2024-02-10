job [[ template "job_name" . ]] {
[[ template "region" . ]]
datacenters = [[ var "datacenters" . | toStringList ]]
type        = "service"

group "app" {
  count = [[ var "count" . ]]

  network {
    mode = "host"
    port "http" {
      to = 8000
    }
  }

  [[ if var "register_service" . ]]
  service {
    name     = "[[ var "service_name" . ]]"
    tags     = [[ var "service_tags" . | toStringList ]]
    provider = "nomad"
    port     = "http"
    check {
      name     = "alive"
      type     = "http"
      path     = "/"
      interval = "10s"
      timeout  = "2s"
    }
  }
  [[ end ]]

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

    template {
      destination = "local/nomad_wait_for_migration.sh"
      change_mode = "noop"
      perms="0755"
      data        = <<EOF
#!/bin/bash

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
EOF
    }

    config {
      image = "[[ var "django_image" . ]]"
      // command = "/django_migration/nomad_wait_for_migration.sh"
      mount {
        type   = "bind"
        source = "local"
        target = "/django_migration"
      }
    }
  }

  task "runserver" {
    driver = "docker"

    config {
      image = "[[ var "django_image" . ]]"
      ports = ["http"]
    }
  }
}
}
