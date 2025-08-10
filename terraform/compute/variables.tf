# Variables for Compute module

## -------------------------------------------------------------------------------------------------------------------
## Required Variables (from networking module)
## -------------------------------------------------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC ID from networking module"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs from networking module"
  type        = list(string)
}

variable "resources_prefix_name" {
  description = "Prefix name for all resources"
  type        = string
}


## -------------------------------------------------------------------------------------------------------------------
## ECS Configuration
## -------------------------------------------------------------------------------------------------------------------
variable "target_capacity" {
  description = "Target capacity utilization for ECS capacity provider"
  type        = number
  default     = 100
}

variable "service_desired_count" {
  description = "Desired number of tasks for ECS service"
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "CPU units for the task definition"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memory (MB) for the task definition"
  type        = number
  default     = 2048
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "application"
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "container_environment" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

## -------------------------------------------------------------------------------------------------------------------
## Auto Scaling Group Configuration
## -------------------------------------------------------------------------------------------------------------------
variable "instance_types" {
  description = "List of EC2 instance types for mixed instances policy (2-4GB RAM, prioritized by cost)"
  type        = list(string)
  default = [
    "t3.small",    # 2GB RAM - cheapest
    "t3a.small",   # 2GB RAM - AMD, cheaper
    "t2.small",    # 2GB RAM - older generation
    "t3.medium",   # 4GB RAM
    "t3a.medium",  # 4GB RAM - AMD, cheaper
    "t2.medium"    # 4GB RAM - older generation
  ]
}

## -------------------------------------------------------------------------------------------------------------------
## Logging Configuration
## -------------------------------------------------------------------------------------------------------------------

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "vpc_origin_id" {
  description = "CloudFront VPC Origin ID"
  type        = string
}

variable "cf_origin_id" {
  description = "CloudFront Origin ID"
  type        = string
}