# Outputs for EC2 module

output "autoscaling_group_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.ecs.arn
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.ecs.name
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.ecs.id
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.ecs.id
}