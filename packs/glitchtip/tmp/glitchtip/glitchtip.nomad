job "glitchtip" {
  datacenters = ["dc1"]

  group "postgres" {

    network {
      port "db" {
        to = 5432
      }
    }

    volume "postgres" {
      type   = "host"
      source = "postgres"
    }

    task "postgres" {
      driver = "docker"

      service {
        name     = "db"
        port     = "db"
        provider = "nomad"
      }

      config {
        image = "postgres:15"
        ports = ["db"]
      }

      env {
        POSTGRES_PASSWORD = "change_me"
        POSTGRES_DB       = "glitchtip"
      }

      volume_mount {
        volume      = "postgres"
        destination = "/var/lib/postgresql/data"
      }
    }
  }

  group "app" {
    count = 1
    network {
      port "web" {
        to = 8000
      }
      port "redis" {
        to = 6379
      }
    }

    restart {
      attempts = 0
    }


    volume "uploads" {
      type   = "host"
      source = "uploads"
    }

    task "redis" {
      driver = "docker"

      service {
        port     = "redis"
        provider = "nomad"
        name     = "redis"
      }

      config {
        image = "redis"
        ports = ["redis"]
      }

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }
    }

    task "web" {
      driver = "docker"

      config {
        image = "glitchtip/glitchtip"
        ports = ["web"]
      }

      template {
        # when postgres service changes, restart this task with updated addr
        # for connecting to pg
        data        = <<EOH
        {{ range nomadService "db" }}
        DB_HOST={{ .Address }}
        DB_PORT={{ .Port }}
        {{ end }}
        {{ range nomadService "redis" }}
        REDIS_HOST={{ .Address }}
        REDIS_PORT={{ .Port }}
        {{ end }}
        EOH
        env         = true
        destination = "local/env.txt"
        change_mode = "restart"
      }

      env {
        // DATABASE_URL                      = ""
        DATABASE_NAME                     = "glitchtip"
        SECRET_KEY                        = "change_me"
        PORT                              = "8000"
        EMAIL_URL                         = "smtp://localhost:25"
        GLITCHTIP_DOMAIN                  = "http://localhost"
        DEFAULT_FROM_EMAIL                = "admin@example.com"
        CELERY_WORKER_AUTOSCALE           = "1,3"
        CELERY_WORKER_MAX_TASKS_PER_CHILD = "1000"
      }

      volume_mount {
        volume      = "uploads"
        destination = "/code/uploads"
      }
    }

    task "worker" {
      driver = "docker"

      config {
        image   = "glitchtip/glitchtip"
        command = "./bin/run-celery-with-beat.sh"
      }

      template {
        # when postgres service changes, restart this task with updated addr
        # for connecting to pg
        data        = <<EOH
        {{ range nomadService "db" }}
        DB_HOST={{ .Address }}
        DB_PORT={{ .Port }}
        {{ end }}
        {{ range nomadService "redis" }}
        REDIS_HOST={{ .Address }}
        REDIS_PORT={{ .Port }}
        {{ end }}
        EOH
        env         = true
        destination = "local/env.txt"
        change_mode = "restart"
      }

      env {
        // DATABASE_URL                      = ""
        DATABASE_NAME                     = "glitchtip"
        SECRET_KEY                        = "change_me"
        PORT                              = "8000"
        EMAIL_URL                         = "smtp://localhost:25"
        GLITCHTIP_DOMAIN                  = "http://localhost"
        DEFAULT_FROM_EMAIL                = "admin@example.com"
        CELERY_WORKER_AUTOSCALE           = "1,3"
        CELERY_WORKER_MAX_TASKS_PER_CHILD = "1000"
      }

      resources {
        cpu    = 500
        memory = 256
      }

      volume_mount {
        volume      = "uploads"
        destination = "/code/uploads"
      }
    }

    // task "migrate" {
    //   driver = "docker"

    //   config {
    //     image   = "glitchtip/glitchtip"
    //     command = "python"
    //     args   = ["manage.py", "migrate"]
    //   }

    //   template {
    //     # when postgres service changes, restart this task with updated addr
    //     # for connecting to pg
    //     data        = <<EOH
    //     {{ range nomadService "db" }}
    //     DB_HOST={{ .Address }}
    //     DB_PORT={{ .Port }}
    //     {{ end }}
    //     {{ range nomadService "redis" }}
    //     REDIS_HOST={{ .Address }}
    //     REDIS_PORT={{ .Port }}
    //     {{ end }}
    //     EOH
    //     env         = true
    //     destination = "local/env.txt"
    //     change_mode = "restart"
    //   }

    //   env {
    //     // DATABASE_URL                      = ""
    //     DATABASE_NAME                     = "glitchtip"
    //     SECRET_KEY                        = "change_me"
    //     PORT                              = "8000"
    //     EMAIL_URL                         = "smtp://localhost:25"
    //     GLITCHTIP_DOMAIN                  = "http://localhost"
    //     DEFAULT_FROM_EMAIL                = "admin@example.com"
    //     CELERY_WORKER_AUTOSCALE           = "1,3"
    //     CELERY_WORKER_MAX_TASKS_PER_CHILD = "1000"
    //   }

    //   resources {
    //     cpu    = 500
    //     memory = 256
    //   }
    // }
  }


  group "debug" {

    volume "uploads" {
      type   = "host"
      source = "uploads"
    }

    task "shell" {
      driver = "docker"

      config {
        image   = "glitchtip/glitchtip"
        command = "bash"
        args = [
          "-c",
          "while true; do sleep 10000; done"
        ]
      }

      template {
        # when postgres service changes, restart this task with updated addr
        # for connecting to pg
        data        = <<EOH
        # all Services:
        {{- range nomadServices }}
        # - {{ .Name }}
        {{- end }}

        # services I care about...
        {{- range nomadService "db" }}
        # DB_HOST={{ .Address }}
        # DB_PORT={{ .Port }}
        DATABASE_URL=postgres://postgres:change_me@{{ .Address }}:{{ .Port}}/glitchtip
        {{- end }}
        # redis:
        {{- range nomadService "redis" }}
        REDIS_HOST={{ .Address }}
        REDIS_PORT={{ .Port }}
        {{- end }}
        EOH
        env         = true
        destination = "local/thing.txt"
        change_mode = "restart"
      }

      env {
        // DATABASE_URL                      = ""
        // DATABASE_NAME                     = "glitchtip"
        SECRET_KEY                        = "change_me"
        PORT                              = "8000"
        EMAIL_URL                         = "smtp://localhost:25"
        GLITCHTIP_DOMAIN                  = "http://localhost"
        DEFAULT_FROM_EMAIL                = "admin@example.com"
        CELERY_WORKER_AUTOSCALE           = "1,3"
        CELERY_WORKER_MAX_TASKS_PER_CHILD = "1000"
      }

      resources {
        cpu    = 500
        memory = 256
      }

      volume_mount {
        volume      = "uploads"
        destination = "/code/uploads"
      }
    }
  }
}
