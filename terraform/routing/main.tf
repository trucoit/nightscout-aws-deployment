# CloudFront Distribution with Private VPC Origins

## -------------------------------------------------------------------------------------------------------------------
## Data Sources
## -------------------------------------------------------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_autoscaling_group" "ecs" {
  name = var.autoscaling_group_name
}

data "aws_instances" "ecs" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [var.autoscaling_group_name]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instance" "ecs" {
  instance_id = data.aws_instances.ecs.ids[0]
}


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
## VPC Origin
## -------------------------------------------------------------------------------------------------------------------
resource "aws_cloudfront_vpc_origin" "cf_origin" {
  vpc_origin_endpoint_config {
    name                   = "${var.resources_prefix_name}-vpc-origin"
    arn                    = "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/${data.aws_instances.ecs.ids[0]}"
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "http-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
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

  # Default placeholder origin - will be updated by Lambda
  origin {
    domain_name = data.aws_instance.ecs.private_dns
    origin_id   = "${var.resources_prefix_name}-cf-origin"

    vpc_origin_config {
      vpc_origin_id = aws_cloudfront_vpc_origin.cf_origin.id
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.resources_prefix_name}-cf-origin"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
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