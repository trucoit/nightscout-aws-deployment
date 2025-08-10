# Variables for Routing module

variable "resources_prefix_name" {
  description = "Prefix name for all resources"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

