job "glitchtip" {
  datacenters = ["dc1"]

  group "postgres" {

    network {
      port "db" {
        to = 5432
      }
    }

    task "postgres" {
      driver = "docker"

      config {
        image = "postgres:15"
        ports = ["db"]
        volumes = [
          "local/pg-data:/var/lib/postgresql/data"
        ]
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

    volume "postgres" {
      type   = "host"
      source = "postgres"
    }
  }

  group "redis" {
    count = 1
    network {
      port "web" {
        to = 8000
      }
    }

    volume "uploads" {
      type   = "host"
      source = "uploads"
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis"
        ports = ["redis"]
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
        {{ range nomadService "postgres" }}
        DB_HOST={{ .Address }}
        DB_PORT={{ .Port }}
        {{ end }}
        EOH
        env         = true
        change_mode = "restart"
      }

      env {
        // DATABASE_URL                      = ""
        DATABASE_NAME                     = "glitchtip"
        SECRET_KEY                        = "change_me"
        PORT                              = "8000"
        EMAIL_URL                         = ""
        GLITCHTIP_DOMAIN                  = ""
        DEFAULT_FROM_EMAIL                = ""
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
          {{ range nomadService "postgres" }}
          DB_HOST={{ .Address }}
          DB_PORT={{ .Port }}
          {{ end }}
          EOH
        env         = true
        change_mode = "restart"
      }

      env {
        // DATABASE_URL                      = ""
        DATABASE_NAME                     = "glitchtip"
        SECRET_KEY                        = "change_me"
        PORT                              = "8000"
        EMAIL_URL                         = ""
        GLITCHTIP_DOMAIN                  = ""
        DEFAULT_FROM_EMAIL                = ""
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

    task "migrate" {
      driver = "docker"

      config {
        image   = "glitchtip/glitchtip"
        command = "./manage.py migrate"
      }

      template {
        # when postgres service changes, restart this task with updated addr
        # for connecting to pg
        data        = <<EOH
        {{ range nomadService "postgres" }}
        DB_HOST={{ .Address }}
        DB_PORT={{ .Port }}
        {{ end }}
        EOH
        env         = true
        change_mode = "restart"
      }

      env {
        // DATABASE_URL                      = ""
        DATABASE_NAME                     = "glitchtip"
        SECRET_KEY                        = "change_me"
        PORT                              = "8000"
        EMAIL_URL                         = ""
        GLITCHTIP_DOMAIN                  = ""
        DEFAULT_FROM_EMAIL                = ""
        CELERY_WORKER_AUTOSCALE           = "1,3"
        CELERY_WORKER_MAX_TASKS_PER_CHILD = "1000"
      }
      resources {
        cpu    = 500
        memory = 256
      }
    }

  }
}
