
# ------------------------------------------------------------------------------
# Job related ------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Migration lifecycle related --------------------------------------------------
variable "migration_poll_seconds" {
  description = "The number of seconds to wait between polls for the 0th alloc to complete running migrations"
  type        = number
  default     = 5
}

variable "migration_poll_iters" {
  description = "The number of iterations to wait for the leader alloc to complete running migrations. If migrations still have not completed, the prestart migration task will fail for the allocation."
  type        = number
  default     = 5
}

# ------------------------------------------------------------------------------
# Networking -------------------------------------------------------------------
variable "port" {
  description = "The port the django_image container listens on"
  type        = number
  default     = 8000
}


variable "service_port_label" {
  description = "The port label for the web app port"
  type        = string
  default     = "http"
}

variable "http_service" {
  description = "Configuration for the application service."
  type = object({
    service_name       = string
    service_tags       = list(string)
    service_provider   = string
    check_enabled      = bool
    check_type         = string
    check_path         = string
    check_interval     = string
    check_timeout      = string
    upstreams = list(object({
      name = string
      port = number
    }))
  })
  default = null
}

# ------------------------------------------------------------------------------
# Docker -----------------------------------------------------------------------
variable "django_image" {
  description = "Docker image for the django application. manage.py should be in the root of the image"
  type        = string
}

variable "env_vars" {
  type = map(string)
  description = "A map of environment variables to set in the container"
  default = {}
}

variable "docker_network_mode" {
  type = string
  description = "Docker network mode. See docker driver config 'network_mode' for details"
  default = null
}

# ------------------------------------------------------------------------------
# Resources/allocations --------------------------------------------------------
variable "count" {
  description = "The number of app instances to deploy"
  type        = number
  default     = 1
}

variable "server_resources" {
  description = "The resources to allocate to the server"
  type        = object({cpu=number, memory=number})
  default     = {
    cpu    = 100
    memory = 300
  }
}

variable "migrate_resources" {
  description = "The resources to allocate to the server"
  type        = object({cpu=number, memory=number})
  default     = {
    cpu    = 100
    memory = 300
  }
}
