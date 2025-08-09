# Outputs for VPC setup with public and private schema

output "pub_private_vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.pub_private_vpc.id
}

output "private_subnet_1_id" {
  description = "Private Subnet A ID"
  value       = var.enable_private_subnets ? aws_subnet.private_subnet_1[0].id : null
}

output "private_subnet_2_id" {
  description = "Private Subnet B ID"
  value       = var.enable_private_subnets ? aws_subnet.private_subnet_2[0].id : null
}

output "private_subnet_3_id" {
  description = "Private Subnet C ID"
  value       = var.enable_private_subnets ? aws_subnet.private_subnet_3[0].id : null
}

output "public_subnet_1_id" {
  description = "Public Subnet A ID"
  value       = aws_subnet.public_subnet_1.id
}

output "public_subnet_2_id" {
  description = "Public Subnet B ID"
  value       = aws_subnet.public_subnet_2.id
}

output "public_subnet_3_id" {
  description = "Public Subnet C ID"
  value       = aws_subnet.public_subnet_3.id
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch Logs log group where the flow logs will be published."
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.log_group[0].arn : null
}

# Additional useful outputs
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = var.enable_private_subnets ? [
    aws_subnet.private_subnet_1[0].id,
    aws_subnet.private_subnet_2[0].id,
    aws_subnet.private_subnet_3[0].id
  ] : []
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
    aws_subnet.public_subnet_3.id
  ]
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.internet_gateway.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = var.enable_private_subnets ? aws_nat_gateway.nat_gateway[0].id : null
}
