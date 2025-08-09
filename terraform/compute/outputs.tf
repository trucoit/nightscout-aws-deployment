# ECS outputs
output "ecs_cluster_id" {
  description = "ECS Cluster ID"
  value       = module.ecs.ecs_cluster_id
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = module.ecs.ecs_cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = module.ecs.ecs_cluster_arn
}

output "ecs_service_id" {
  description = "ECS Service ID"
  value       = module.ecs.ecs_service_id
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = module.ecs.ecs_service_name
}

output "task_definition_arn" {
  description = "Task Definition ARN"
  value       = module.ecs.task_definition_arn
}

output "capacity_provider_name" {
  description = "ECS Capacity Provider name"
  value       = module.ecs.capacity_provider_name
}

# EC2 outputs
output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = module.ec2.autoscaling_group_name
}

output "autoscaling_group_arn" {
  description = "Auto Scaling Group ARN"
  value       = module.ec2.autoscaling_group_arn
}

output "security_group_id" {
  description = "Security Group ID for ECS instances"
  value       = module.ec2.security_group_id
}

# Shared outputs
output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.main.name
}