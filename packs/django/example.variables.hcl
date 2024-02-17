env_vars = {
  DEBUG             = "off",
  POSTGRES_NAME     = "django_pack_postgres",
  POSTGRES_USER     = "postgres",
  POSTGRES_PASSWORD = "password",
  POSTGRES_HOST     = "127.0.0.1",
  POSTGRES_PORT     = "5432",
}
docker_network_mode="host"
count = 2
http_service = {
  service_name       = "django"
  service_provider = "nomad"
  service_tags       = []
  check_enabled      = true
  check_type         = "http"
  check_path         = "/"
  check_interval     = "10s"
  check_timeout      = "5s"
}