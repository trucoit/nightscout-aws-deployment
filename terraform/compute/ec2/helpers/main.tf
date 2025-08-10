# Helper resources for EC2 Auto Scaling Group

## -------------------------------------------------------------------------------------------------------------------
## Data Sources
## -------------------------------------------------------------------------------------------------------------------
data "aws_region" "current" {}

## -------------------------------------------------------------------------------------------------------------------
## SNS Topic for ASG Notifications
## -------------------------------------------------------------------------------------------------------------------
resource "aws_sns_topic" "asg_notifications" {
  name = "${var.resources_prefix_name}-asg-notifications"

  tags = {
    Name = "${var.resources_prefix_name}-asg-notifications"
  }
}

## -------------------------------------------------------------------------------------------------------------------
## Auto Scaling Group Notification
## -------------------------------------------------------------------------------------------------------------------
resource "aws_autoscaling_notification" "asg_notifications" {
  group_names = [var.autoscaling_group_name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.asg_notifications.arn
}

## -------------------------------------------------------------------------------------------------------------------
## CloudFront Update Lambda Module
## -------------------------------------------------------------------------------------------------------------------
module "cloudfront_update_lambda" {
  source = "./com.lambda.cloudfrontupdate"

  resources_prefix_name      = var.resources_prefix_name
  log_group_name             = var.log_group_name
  sns_topic_arn              = aws_sns_topic.asg_notifications.arn
  cloudfront_distribution_id = var.cloudfront_distribution_id
  container_port             = var.container_port
}