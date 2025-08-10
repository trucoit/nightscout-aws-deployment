# CloudFront Update Lambda Function

## -------------------------------------------------------------------------------------------------------------------
## Data Sources
## -------------------------------------------------------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

## -------------------------------------------------------------------------------------------------------------------
## Lambda Function Package
## -------------------------------------------------------------------------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function.zip"
}

## -------------------------------------------------------------------------------------------------------------------
## CloudWatch Log Group for Lambda
## -------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "${var.log_group_name}/lambda/cloudfront-update"
  retention_in_days = 30

  tags = {
    Name = "${var.resources_prefix_name}-cloudfront-update-logs"
  }
}

## -------------------------------------------------------------------------------------------------------------------
## IAM Role for Lambda
## -------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "lambda" {
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
## IAM Policy for Lambda
## -------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda" {
  name = "${var.resources_prefix_name}-cloudfront-update-lambda-policy"
  role = aws_iam_role.lambda.id

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
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
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
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

## -------------------------------------------------------------------------------------------------------------------
## Lambda Function
## -------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_function" "cloudfront_update" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.resources_prefix_name}-cloudfront-update"
  role            = aws_iam_role.lambda.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = 60
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      CLOUDFRONT_DISTRIBUTION_ID = var.cloudfront_distribution_id
      CONTAINER_PORT            = var.container_port
      LOG_LEVEL                 = "INFO"
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = {
    Name = "${var.resources_prefix_name}-cloudfront-update"
  }
}

## -------------------------------------------------------------------------------------------------------------------
## SNS Topic Subscription
## -------------------------------------------------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cloudfront_update.arn
}

## -------------------------------------------------------------------------------------------------------------------
## Lambda Permission for SNS
## -------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudfront_update.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}