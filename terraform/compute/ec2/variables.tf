# Variables for EC2 module

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "resources_prefix_name" {
  description = "Prefix name for all resources"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
}

variable "instance_types" {
  description = "List of EC2 instance types"
  type        = list(string)
}

variable "container_port" {
  description = "Container port for security group"
  type        = number
}