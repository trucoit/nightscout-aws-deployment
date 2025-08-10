# CloudFront Update Lambda Function

This Lambda function automatically updates CloudFront distribution origins when EC2 instances are launched or terminated in the Auto Scaling Group.

## Functionality

### Event Processing
- Receives SNS notifications from Auto Scaling Group lifecycle events
- Processes instance launch, termination, and error events
- Extracts instance information from SNS messages

### Origin Management
- Queries Auto Scaling Group for currently running instances
- Retrieves private IP addresses of healthy instances
- Updates CloudFront distribution with new origin configuration
- Handles cases with no running instances (placeholder origin)

### Logging
- Comprehensive logging to CloudWatch with configurable log levels
- Logs all operations, errors, and instance changes
- Uses structured logging for better observability

## Environment Variables

- `CLOUDFRONT_DISTRIBUTION_ID`: Target CloudFront distribution ID
- `CONTAINER_PORT`: Port number for origin configuration
- `LOG_LEVEL`: Logging level (INFO, DEBUG, WARNING, ERROR)

## IAM Permissions

The Lambda function requires permissions for:
- CloudWatch Logs (create log groups, streams, put events)
- CloudFront (get/update distribution configuration)
- EC2 (describe instances)
- Auto Scaling (describe auto scaling groups)

## Error Handling

- Graceful error handling with detailed logging
- Returns appropriate HTTP status codes
- Continues processing even if some operations fail
- Automatic retry through SNS message redelivery

## Integration

- Triggered by SNS topic subscribed to ASG notifications
- Deployed with Terraform using ZIP packaging
- Integrated with CloudWatch for monitoring and alerting