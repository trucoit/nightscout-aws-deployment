variable "resources_prefix_name" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EFS will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EFS mount targets"
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "Security group ID of EC2 instances that need EFS access"
  type        = string
}