# Variables for ECS module

variable "resources_prefix_name" {
  description = "Prefix name for all resources"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "autoscaling_group_arn" {
  description = "Auto Scaling Group ARN"
  type        = string
}

variable "target_capacity" {
  description = "Target capacity utilization for ECS capacity provider"
  type        = number
}

variable "service_desired_count" {
  description = "Desired number of tasks for ECS service"
  type        = number
}

variable "task_cpu" {
  description = "CPU units for the task definition"
  type        = number
  default     = null
}

variable "task_memory" {
  description = "Memory (MB) for the task definition"
  type        = number
  default     = null
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
}

variable "container_environment" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
}