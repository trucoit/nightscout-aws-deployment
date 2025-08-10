# Outputs for Routing module

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront Distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "vpc_origin_id" {
  description = "CloudFront VPC Origin ID"
  value       = aws_cloudfront_vpc_origin.cf_origin.id
}

output "cf_origin_id" {
  description = "CloudFront Origin ID"
  value       = "${var.resources_prefix_name}-cf-origin"
}