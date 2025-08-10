import json
import logging
import os
import time
import boto3
from typing import Dict, List, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize AWS clients
cloudfront = boto3.client('cloudfront')
ec2 = boto3.client('ec2')

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda function to update CloudFront distribution origins when ASG instances change.
    
    Args:
        event: SNS event containing ASG notification
        context: Lambda context object
        
    Returns:
        Dict containing status and message
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Parse SNS message
        sns_message = json.loads(event['Records'][0]['Sns']['Message'])
        logger.info(f"SNS message: {json.dumps(sns_message)}")
        
        # Extract ASG information
        asg_name = sns_message.get('AutoScalingGroupName')
        event_type = sns_message.get('Event')
        instance_id = sns_message.get('EC2InstanceId')
        
        logger.info(f"Processing {event_type} for instance {instance_id} in ASG {asg_name}")
        
        # Get environment variables
        distribution_id = os.environ['CLOUDFRONT_DISTRIBUTION_ID']
        container_port = os.environ['CONTAINER_PORT']
        
        # Get current running instances in the ASG
        running_instances = get_asg_running_instances(asg_name)
        logger.info(f"Found Running instance: {running_instances}")
        
        # Update CloudFront distribution
        update_cloudfront_origins(distribution_id, running_instances, container_port)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully updated CloudFront distribution {distribution_id}',
                'instances': running_instances
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }

def get_asg_running_instances(asg_name: str) -> List[str]:
    """
    Get list of running instance IPs from Auto Scaling Group.
    
    Args:
        asg_name: Auto Scaling Group name
        
    Returns:
        List of private IP addresses of running instances
    """
    try:
        # Get ASG instances
        autoscaling = boto3.client('autoscaling')
        response = autoscaling.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name]
        )
        
        if not response['AutoScalingGroups']:
            logger.warning(f"ASG {asg_name} not found")
            return []
        
        asg = response['AutoScalingGroups'][0]
        
        # Retry with exponential backoff for InService instances
        max_retries = 5
        base_delay = 2
        
        for attempt in range(max_retries):
            instance_ids = [instance['InstanceId'] for instance in asg['Instances'] 
                           if instance['LifecycleState'] == 'InService']
            
            if instance_ids:
                break
                
            if attempt < max_retries - 1:
                delay = base_delay ** (attempt + 1)
                logger.info(f"No InService instances found, retrying in {delay}s (attempt {attempt + 1}/{max_retries})")
                time.sleep(delay)
                
                # Re-fetch ASG data for next attempt
                response = autoscaling.describe_auto_scaling_groups(
                    AutoScalingGroupNames=[asg_name]
                )
                asg = response['AutoScalingGroups'][0]
        
        if not instance_ids:
            logger.info("No InService instances found after all retries")
            return []
        
        # Get instance details
        ec2_response = ec2.describe_instances(InstanceIds=instance_ids)
        
        running_instances = []
        for reservation in ec2_response['Reservations']:
            for instance in reservation['Instances']:
                if instance['State']['Name'] == 'running':
                    running_instances.append(instance)
        
        if not running_instances:
            return []
        
        # Get the most recently launched running instance
        latest_instance = max(running_instances, key=lambda x: x['LaunchTime'])
        
        private_dns = latest_instance.get('PrivateDnsName')
        instance_arn = f"arn:aws:ec2:{latest_instance['Placement']['AvailabilityZone'][:-1]}:{latest_instance.get('OwnerId', '')}:instance/{latest_instance['InstanceId']}"
        
        logger.info(f"Found latest running instance {latest_instance['InstanceId']} with DNS {private_dns}")
        
        return {'private_dns': private_dns, 'instance_arn': instance_arn}
        
    except Exception as e:
        logger.error(f"Error getting ASG instances: {str(e)}")
        raise

def update_cloudfront_origins(distribution_id: str, instance_data: Dict[str, str], container_port: str) -> None:
    """
    Update CloudFront distribution with new origin configuration for a single EC2 instance.
    
    Args:
        distribution_id: CloudFront distribution ID
        instance_data: Dict containing 'private_dns' and 'instance_arn' of the EC2 instance
        container_port: Container port number
    """
    try:
        # Get environment variables for origin IDs
        vpc_origin_id = os.environ['VPC_ORIGIN_ID']
        cf_origin_id = os.environ['CF_ORIGIN_ID']
        
        # Get current VPC origin config for ETag
        vpc_origin_response = cloudfront.get_vpc_origin(Id=vpc_origin_id)
        vpc_origin_etag = vpc_origin_response['ETag']
        
        # Update VPC origin ARN
        cloudfront.update_vpc_origin(
            Id=vpc_origin_id,
            VpcOriginEndpointConfig={
                'Name': f"{os.environ.get('RESOURCES_PREFIX', 'nightscout')}-vpc-origin",
                'Arn': instance_data['instance_arn'],
                'HTTPPort': int(container_port),
                'HTTPSPort': 443,
                'OriginProtocolPolicy': 'http-only',
                'OriginSslProtocols': {
                    'Items': ['TLSv1.2'],
                    'Quantity': 1
                }
            },
            IfMatch=vpc_origin_etag
        )
        
        # Get current distribution config
        response = cloudfront.get_distribution_config(Id=distribution_id)
        config = response['DistributionConfig'].copy()
        etag = response['ETag']
        
        # Update the origin domain name
        origins = config['Origins']['Items']
        for origin in origins:
            if origin['Id'] == cf_origin_id:
                origin['DomainName'] = instance_data['private_dns']
                logger.info(f"Updated origin {cf_origin_id} with DNS: {instance_data['private_dns']}")
                break
        
        config['Origins']['Items'] = origins
        
        # Update distribution
        cloudfront.update_distribution(
            Id=distribution_id,
            DistributionConfig=config,
            IfMatch=etag
        )
        
        logger.info(f"Successfully updated CloudFront distribution {distribution_id} and VPC origin {vpc_origin_id}")
        
    except Exception as e:
        logger.error(f"Error updating CloudFront distribution: {str(e)}")
        raise