# Variables for CloudFront Update Lambda

variable "resources_prefix_name" {
  description = "Prefix name for all resources"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS Topic ARN for ASG notifications"
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