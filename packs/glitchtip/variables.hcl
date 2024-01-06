variable "postgres_password" {
  description = "The password for the postgres user"
  type        = string
  default     = "change_me"
}

variable "postgres_db" {
  description = "The password for the postgres user"
  type        = string
  default     = "glitchtip"
}


// variable "database_url"{
//   description = "database_url"
//   type = string
//   default = "postgres://postgres:{{postgres_password}}@localhost:5432/postgres"
// }

variable "secret_key"{
  description = "secret_key"
  type = string
  default = "change_me"
}

// variable "port"{
//   description = "port"
//   type = string
//   default = ""
// }

variable "email_url"{
  description = "email_url"
  type = string
  default = "smtp://localhost:25"
}
variable "glitchtip_domain"{
  description = "glitchtip_domain"
  type = string
  // TODO: no default?
  default = "http://localhost"
}
variable "default_from_email"{
  description = "default_from_email"
  type = string
  default = "admin@example.com"
}

variable "celery_worker_autoscale"{
  description = "celery_worker_autoscale"
  type = string
  default = "1,3"
}

variable "celery_worker_max_tasks_per_child"{
  description = "celery_worker_max_tasks_per_child"
  type = string
  default = "1000"
}










variable "job_name" {
  # If "", the pack name will be used
  description = "The name to use as the job name which overrides using the pack name"
  type        = string
  default     = ""
}

variable "region" {
  description = "The region where jobs will be deployed"
  type        = string
  default     = ""
}

variable "datacenters" {
  description = "A list of datacenters in the region which are eligible for task placement"
  type        = list(string)
  default     = ["*"]
}

variable "count" {
  description = "The number of app instances to deploy"
  type        = number
  default     = 2
}

variable "message" {
  description = "The message your application will render"
  type        = string
  default     = "Hello World!"
}

variable "register_service" {
  description = "If you want to register a Nomad service for the job"
  type        = bool
  default     = true
}

variable "service_name" {
  description = "The service name for the glitchtip application"
  type        = string
  default     = "webapp"
}

variable "service_tags" {
  description = "The service tags for the glitchtip application"
  type        = list(string)
  # The default value is shaped to integrate with Traefik
  # This routes at the root path "/", to route to this service from
  # another path, change "urlprefix-/" to "urlprefix-/<PATH>" and
  # "traefik.http.routers.http.rule=Path(∫/∫)" to
  # "traefik.http.routers.http.rule=Path(∫/<PATH>∫)"
  default = [
    "urlprefix-/",
    "traefik.enable=true",
    "traefik.http.routers.http.rule=Path(`/`)",
  ]
}
