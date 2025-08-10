# Outputs for EC2 helpers

output "sns_topic_arn" {
  description = "SNS Topic ARN for ASG notifications"
  value       = aws_sns_topic.asg_notifications.arn
}

output "lambda_function_arn" {
  description = "CloudFront Update Lambda Function ARN"
  value       = module.cloudfront_update_lambda.lambda_function_arn
}