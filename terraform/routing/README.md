# Routing Module

This module creates a CloudFront distribution that routes traffic directly to EC2 instances in the Auto Scaling Group without using an Application Load Balancer (ALB) to save costs.

## Architecture

- **CloudFront Distribution**: Global CDN that routes traffic to private VPC origins
- **Private VPC Origins**: EC2 instances in the Auto Scaling Group are configured as origins
- **Lambda Function**: Automatically updates CloudFront origins when instances are launched/terminated
- **SNS Integration**: Auto Scaling Group notifications trigger the Lambda function

## Components

### CloudFront Distribution
- Configured with private VPC origins pointing to EC2 instances
- Uses HTTP-only protocol to communicate with instances
- Caches disabled for dynamic content
- Redirects HTTP to HTTPS for viewers

### Lambda Function Integration
The Lambda function (`com.lambda.cloudfrontupdate`) automatically:
1. Receives SNS notifications when ASG instances change
2. Queries the Auto Scaling Group for running instances
3. Updates CloudFront distribution origins with current instance IPs
4. Handles instance launch, termination, and error events

## Usage

The module is automatically integrated with the compute module and requires:
- `resources_prefix_name`: Prefix for resource naming
- `container_port`: Port exposed by the application container
- `vpc_origins`: List of VPC origins (managed by Lambda)

## Outputs

- `cloudfront_distribution_id`: CloudFront Distribution ID
- `cloudfront_distribution_arn`: CloudFront Distribution ARN  
- `cloudfront_domain_name`: CloudFront Distribution domain name

## Cost Optimization

This setup avoids ALB costs by routing traffic directly to EC2 instances through CloudFront, while maintaining high availability and automatic scaling capabilities.