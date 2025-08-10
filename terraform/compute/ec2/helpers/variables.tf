# Variables for EC2 helpers

variable "resources_prefix_name" {
  description = "Prefix name for all resources"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "vpc_origin_id_alpha" {
  description = "CloudFront VPC Origin ID"
  type        = string
}

variable "cf_origin_id_alpha" {
  description = "CloudFront Origin ID"
  type        = string
}

variable "vpc_origin_id_bravo" {
  description = "CloudFront VPC Origin ID"
  type        = string
}

variable "cf_origin_id_bravo" {
  description = "CloudFront Origin ID"
  type        = string
}