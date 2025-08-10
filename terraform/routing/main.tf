# CloudFront Distribution with Private VPC Origins

## -------------------------------------------------------------------------------------------------------------------
## Data Sources
## -------------------------------------------------------------------------------------------------------------------
data "aws_region" "current" {}

## -------------------------------------------------------------------------------------------------------------------
## CloudFront Origin Access Control
## -------------------------------------------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.resources_prefix_name}-oac"
  description                       = "Origin Access Control for ${var.resources_prefix_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

## -------------------------------------------------------------------------------------------------------------------
## CloudFront Distribution
## -------------------------------------------------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "main" {
  comment             = "${var.resources_prefix_name} CloudFront Distribution"
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  retain_on_delete    = false
  staging             = false
  http_version        = "http2and3"
  price_class         = "PriceClass_100"

  ## 
  # ORIGIN Config
  create_vpc_origin = true
  vpc_origin = {
    ec2_vpc_origin = {
      name                   = random_pet.this.id
      arn                    = module.ec2.arn
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = {
        items    = ["TLSv1.2"]
        quantity = 1
      }
    }
  }

  # Default placeholder origin - will be updated by Lambda
  origin {
    domain_name = "example.com"
    origin_id   = "${var.resources_prefix_name}-cf-origin"

    custom_origin_config {
      http_port              = var.container_port
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "placeholder"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 10
    default_ttl = 1400
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.resources_prefix_name}-cloudfront"
  }
}