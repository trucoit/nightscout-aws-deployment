# Outputs for ECS module

output "ecs_cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_id" {
  description = "ECS Service ID"
  value       = aws_ecs_service.main.id
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.main.name
}

output "task_definition_arn" {
  description = "Task Definition ARN"
  value       = aws_ecs_task_definition.main.arn
}

output "capacity_provider_name" {
  description = "ECS Capacity Provider name"
  value       = aws_ecs_capacity_provider.main.name
}