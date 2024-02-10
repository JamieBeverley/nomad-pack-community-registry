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
  default     = 1
}

variable "register_service" {
  description = "If you want to register a Nomad service for the Django application"
  type        = bool
  default     = true
}

variable "service_name" {
  description = "The service name for the django_example application"
  type        = string
  default     = "djangoapp"
}

variable "service_tags" {
  description = "The service tags for the django_example application"
  type        = list(string)
  default = []
}

variable "service_check" {
  description = "The service check for the django_example application"
  type        = map(string)
  default     = null
}

variable "http_service" {
  description = "If true, the service check will be an HTTP check"
  type        = map(string)
  default     = null
}

# django sepcific
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

variable "port" {
  description = "The port the django_image container listens on"
  type        = number
  default     = 8000
}

variable "django_image" {
  description = "Docker image for the django_example application. manage.py should be in the root of the image"
  type        = string
}

variable "env_vars" {
  type = map(string)
  description = "A map of environment variables to set in the container"
  default = {}
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
