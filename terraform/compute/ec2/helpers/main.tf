# Helper resources for EC2 Auto Scaling Group

## -------------------------------------------------------------------------------------------------------------------
## Data Sources
## -------------------------------------------------------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


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
    #"autoscaling:EC2_INSTANCE_TERMINATE",
    #"autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    #"autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.asg_notifications.arn
}


## -------------------------------------------------------------------------------------------------------------------
## CloudFront Update Lambda Function Package
## -------------------------------------------------------------------------------------------------------------------
data "archive_file" "cloudfront_update_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/com.lambda.cloudfrontupdate"
  output_path = "${path.module}/com.lambda.cloudfrontupdate.zip"
  excludes    = ["README.md", "test_event.json"]
}


## -------------------------------------------------------------------------------------------------------------------
## CloudFront Update Lambda IAM Role
## -------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "cloudfront_update_lambda" {
  name = "${var.resources_prefix_name}-cloudfront-update-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.resources_prefix_name}-cloudfront-update-lambda-role"
  }
}


## -------------------------------------------------------------------------------------------------------------------
## CloudFront Update Lambda IAM Policy
## -------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "cloudfront_update_lambda" {
  name = "${var.resources_prefix_name}-cloudfront-update-lambda-policy"
  role = aws_iam_role.cloudfront_update_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:UpdateDistribution"
        ]
        Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cloudfront_distribution_id}"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

## -------------------------------------------------------------------------------------------------------------------
## CloudFront Update Lambda Function
## -------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_function" "cloudfront_update" {
  filename         = data.archive_file.cloudfront_update_lambda_zip.output_path
  function_name    = "${var.resources_prefix_name}-cloudfront-update"
  role            = aws_iam_role.cloudfront_update_lambda.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = 600
  source_code_hash = data.archive_file.cloudfront_update_lambda_zip.output_base64sha256

  logging_config {
    log_group  = var.log_group_name
    log_format = "Text"
  }

  environment {
    variables = {
      CLOUDFRONT_DISTRIBUTION_ID = var.cloudfront_distribution_id
      CONTAINER_PORT            = var.container_port
      VPC_ORIGIN_ID             = var.vpc_origin_id
      CF_ORIGIN_ID              = var.cf_origin_id
      LOG_LEVEL                 = "INFO"
    }
  }

  depends_on = [
    aws_iam_role_policy.cloudfront_update_lambda,
  ]

  tags = {
    Name = "${var.resources_prefix_name}-cloudfront-update"
  }
}


## -------------------------------------------------------------------------------------------------------------------
## CloudFront Update Lambda SNS Topic Subscription
## -------------------------------------------------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "cloudfront_update_lambda" {
  topic_arn = aws_sns_topic.asg_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cloudfront_update.arn
}


## -------------------------------------------------------------------------------------------------------------------
## CloudFront Update Lambda Permission for SNS
## -------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_permission" "cloudfront_update_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudfront_update.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.asg_notifications.arn
}