job [[ template "job_name" . ]] {
[[ template "region" . ]]
datacenters = [[ var "datacenters" . | toStringList ]]
type        = "service"

group "app" {
  count = [[ var "count" . ]]

  network {
    mode = "host"
    port "http" {
      to = [[ var "port" . ]]
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

    env {
      [[- range $key, $val := var "env_vars" . ]]
      [[ $key ]] = [[ $val | quote ]]
      [[- end ]]
    }

    config {
      image = "[[ var "django_image" . ]]"
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

RETRIES=[[ var "migration_poll_iters" . ]]
WAIT_SECONDS=[[ var "migration_poll_seconds" . ]]

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

  task "runserver" {
    driver = "docker"
    
    env {
      [[- range $key, $val := var "env_vars" . ]]
      [[ $key ]] = [[ $val | quote ]]
      [[- end ]]
    }

    config {
      image = "[[ var "django_image" . ]]"
      ports = ["http"]
    }
  }
}
}
