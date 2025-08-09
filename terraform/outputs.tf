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

output "public_subnet_1_id" {
  description = "Public Subnet A ID"
  value       = module.networking.public_subnet_1_id
}

output "public_subnet_2_id" {
  description = "Public Subnet B ID"
  value       = module.networking.public_subnet_2_id
}

output "public_subnet_3_id" {
  description = "Public Subnet C ID"
  value       = module.networking.public_subnet_3_id
}

output "private_subnet_1_id" {
  description = "Private Subnet A ID"
  value       = module.networking.private_subnet_1_id
}

output "private_subnet_2_id" {
  description = "Private Subnet B ID"
  value       = module.networking.private_subnet_2_id
}

output "private_subnet_3_id" {
  description = "Private Subnet C ID"
  value       = module.networking.private_subnet_3_id
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
