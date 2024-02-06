job [[ template "job_name" . ]] {
  [[ template "region" . ]]
  datacenters = [[ var "datacenters" . | toStringList ]]
  type = "service"

  group "app" {
    count = [[ var "count" . ]]

    network {
    }

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["http"]
      }

      env {
        MESSAGE = [[ var "message" . | quote ]]
      }
    }
  }
}
