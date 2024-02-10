job [[ template "job_name" . ]] {
  [[ template "region" . ]]
  datacenters = [[ var "datacenters" . | toStringList ]]
  type        = "service"

  group "app" {
    count = [[ var "count" . ]]

    network {
      mode = "host"
      port [[ var "service_port_label" .  | quote ]] {
        to = [[ var "port" . ]]
      }
    }

    [[- if var "http_service" . ]]
    [[ $service := var "http_service" . ]]
    service {
        name = [[ $service.service_name | quote ]]
        port = [[ var "service_port_label" .  | quote ]]
        tags = [[ $service.service_tags | toStringList ]]
        provider = [[ $service.service_provider | quote ]]
        [[- if $service.upstreams ]]
        connect {
          sidecar_service {
            proxy {
              [[- range $upstream := $service.upstreams ]]
              upstreams {
                destination_name = [[ $upstream.name | quote ]]
                local_bind_port  = [[ $upstream.port ]]
              }
              [[- end ]]
            }
          }
        }
        [[- end ]]
        
        [[- if $service.check_enabled ]]
        check {
          type     = [[ $service.check_type | quote ]]
          [[- if $service.check_path]]
          path     = [[ $service.check_path | quote ]]
          [[- end ]]
          interval = [[ $service.check_interval | quote ]]
          timeout  = [[ $service.check_timeout | quote ]]
        }
        [[- end]]
      }
    [[- end ]]

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
        [[ template "expand_map" (var "env_vars" .) ]]
      }

      config {
        image   = "[[ var "django_image" . ]]"
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

      [[ template "resources" (var "server_resources" . ) ]]

    }

    task "server" {
      driver = "docker"

      env {
        [[ template "expand_map" (var "env_vars" .) ]]
      }

      config {
        image = "[[ var "django_image" . ]]"
        ports = ["http"]
      }

      [[ template "resources" (var "server_resources" . ) ]]
    }
  }
}
