# Outputs for VPC setup with public and private schema

output "pub_private_vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.pub_private_vpc.id
}

output "private_subnet_ids_by_az" {
  description = "Map of private subnet IDs by availability zone"
  value       = { for k, v in aws_subnet.private_subnets : k => v.id }
}

output "public_subnet_ids_by_az" {
  description = "Map of public subnet IDs by availability zone"
  value       = { for k, v in aws_subnet.public_subnets : k => v.id }
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch Logs log group where the flow logs will be published."
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.log_group[0].arn : null
}

# Additional useful outputs
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = values(aws_subnet.private_subnets)[*].id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = values(aws_subnet.public_subnets)[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.internet_gateway.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = var.enable_private_subnets ? aws_nat_gateway.nat_gateway[0].id : null
}
