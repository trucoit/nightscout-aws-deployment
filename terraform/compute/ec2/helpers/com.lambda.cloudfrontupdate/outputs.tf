# Outputs for CloudFront Update Lambda

output "lambda_function_arn" {
  description = "Lambda Function ARN"
  value       = aws_lambda_function.cloudfront_update.arn
}

output "lambda_function_name" {
  description = "Lambda Function name"
  value       = aws_lambda_function.cloudfront_update.function_name
}