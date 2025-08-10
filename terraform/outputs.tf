# Outputs for Nightscout AWS Deployment

# Configuration Values
output "aws_region" {
  description = "AWS region used for deployment"
  value       = var.aws_region
}

output "resources_prefix_name" {
  description = "Prefix name used for all resources"
  value       = var.resources_prefix_name
}

# Networking Module Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.pub_private_vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids_by_az" {
  description = "Map of public subnet IDs by availability zone"
  value       = module.networking.public_subnet_ids_by_az
}

output "private_subnet_ids_by_az" {
  description = "Map of private subnet IDs by availability zone"
  value       = module.networking.private_subnet_ids_by_az
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.networking.internet_gateway_id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.networking.nat_gateway_id
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch Logs log group where the flow logs will be published."
  value       = module.networking.log_group_arn
}

# Routing Module Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = module.routing.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution domain name"
  value       = module.routing.cloudfront_domain_name
}

# Compute Module Outputs
output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.autoscaling_group_name
}
