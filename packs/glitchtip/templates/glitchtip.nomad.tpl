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
        name = "db"
        port = "db"
        provider = "nomad"
      }

      config {
        image = "postgres:15"
        ports = ["db"]
      }

      env {
        POSTGRES_PASSWORD = "[[ var "postgres_password" .  ]]"
        POSTGRES_DB       = "[[ var "postgres_db" . ]]"
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
        port = "redis"
        provider = "nomad"
        name = "redis"
      }

      config {
        image = "redis"
        ports = ["redis"]
      }
      
      lifecycle {
        hook = "prestart"
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
        // DATABASE_URL                      = "[[ var "database_url" . ]]"
        DATABASE_NAME                     = "[[ var "postgres_db" . ]]"
        SECRET_KEY                        = "[[ var "secret_key" . ]]"
        PORT                              = "8000"
        EMAIL_URL                         = "[[ var "email_url" . ]]"
        GLITCHTIP_DOMAIN                  = "[[ var "glitchtip_domain" . ]]"
        DEFAULT_FROM_EMAIL                = "[[ var "default_from_email" . ]]"
        CELERY_WORKER_AUTOSCALE           = "[[ var "celery_worker_autoscale" . ]]"
        CELERY_WORKER_MAX_TASKS_PER_CHILD = "[[ var "celery_worker_max_tasks_per_child" . ]]"
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
        // DATABASE_URL                      = "[[ var "database_url" . ]]"
        DATABASE_NAME                     = "[[ var "postgres_db" . ]]"
        SECRET_KEY                        = "[[ var "secret_key" . ]]"
        PORT                              = "8000"
        EMAIL_URL                         = "[[ var "email_url" . ]]"
        GLITCHTIP_DOMAIN                  = "[[ var "glitchtip_domain" . ]]"
        DEFAULT_FROM_EMAIL                = "[[ var "default_from_email" . ]]"
        CELERY_WORKER_AUTOSCALE           = "[[ var "celery_worker_autoscale" . ]]"
        CELERY_WORKER_MAX_TASKS_PER_CHILD = "[[ var "celery_worker_max_tasks_per_child" . ]]"
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
        command = "python"
        args   = ["manage.py", "migrate"]
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
        // DATABASE_URL                      = "[[ var "database_url" . ]]"
        DATABASE_NAME                     = "[[ var "postgres_db" . ]]"
        SECRET_KEY                        = "[[ var "secret_key" . ]]"
        PORT                              = "8000"
        EMAIL_URL                         = "[[ var "email_url" . ]]"
        GLITCHTIP_DOMAIN                  = "[[ var "glitchtip_domain" . ]]"
        DEFAULT_FROM_EMAIL                = "[[ var "default_from_email" . ]]"
        CELERY_WORKER_AUTOSCALE           = "[[ var "celery_worker_autoscale" . ]]"
        CELERY_WORKER_MAX_TASKS_PER_CHILD = "[[ var "celery_worker_max_tasks_per_child" . ]]"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Debugging only.
    

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
        DB_HOST={{ .Address }}
        DB_PORT={{ .Port }}
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
        // DATABASE_URL                      = "[[ var "database_url" . ]]"
        DATABASE_NAME                     = "[[ var "postgres_db" . ]]"
        SECRET_KEY                        = "[[ var "secret_key" . ]]"
        PORT                              = "8000"
        EMAIL_URL                         = "[[ var "email_url" . ]]"
        GLITCHTIP_DOMAIN                  = "[[ var "glitchtip_domain" . ]]"
        DEFAULT_FROM_EMAIL                = "[[ var "default_from_email" . ]]"
        CELERY_WORKER_AUTOSCALE           = "[[ var "celery_worker_autoscale" . ]]"
        CELERY_WORKER_MAX_TASKS_PER_CHILD = "[[ var "celery_worker_max_tasks_per_child" . ]]"
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
