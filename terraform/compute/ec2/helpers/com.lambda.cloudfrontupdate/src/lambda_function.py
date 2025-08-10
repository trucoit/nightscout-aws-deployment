import json
import logging
import os
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
        logger.info(f"Found {len(running_instances)} running instances: {running_instances}")
        
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
        instance_ids = [instance['InstanceId'] for instance in asg['Instances'] 
                       if instance['LifecycleState'] == 'InService']
        
        if not instance_ids:
            logger.info("No running instances found in ASG")
            return []
        
        # Get instance details
        ec2_response = ec2.describe_instances(InstanceIds=instance_ids)
        
        running_ips = []
        for reservation in ec2_response['Reservations']:
            for instance in reservation['Instances']:
                if instance['State']['Name'] == 'running':
                    private_ip = instance.get('PrivateIpAddress')
                    if private_ip:
                        running_ips.append(private_ip)
                        logger.info(f"Found running instance {instance['InstanceId']} with IP {private_ip}")
        
        return running_ips
        
    except Exception as e:
        logger.error(f"Error getting ASG instances: {str(e)}")
        raise

def update_cloudfront_origins(distribution_id: str, instance_ips: List[str], container_port: str) -> None:
    """
    Update CloudFront distribution with new origin configuration.
    
    Args:
        distribution_id: CloudFront distribution ID
        instance_ips: List of instance private IP addresses
        container_port: Container port number
    """
    try:
        # Get current distribution config
        response = cloudfront.get_distribution_config(Id=distribution_id)
        config = response['DistributionConfig']
        etag = response['ETag']
        
        logger.info(f"Current distribution has {len(config['Origins']['Items'])} origins")
        
        # Create new origins list
        new_origins = []
        for i, ip in enumerate(instance_ips):
            origin_id = f"ec2-instance-{i+1}"
            new_origins.append({
                'Id': origin_id,
                'DomainName': ip,
                'CustomOriginConfig': {
                    'HTTPPort': int(container_port),
                    'HTTPSPort': 443,
                    'OriginProtocolPolicy': 'http-only',
                    'OriginSslProtocols': {
                        'Quantity': 1,
                        'Items': ['TLSv1.2']
                    }
                }
            })
        
        # If no instances, create a placeholder origin
        if not new_origins:
            logger.warning("No running instances found, creating placeholder origin")
            new_origins.append({
                'Id': 'placeholder',
                'DomainName': 'example.com',
                'CustomOriginConfig': {
                    'HTTPPort': int(container_port),
                    'HTTPSPort': 443,
                    'OriginProtocolPolicy': 'http-only',
                    'OriginSslProtocols': {
                        'Quantity': 1,
                        'Items': ['TLSv1.2']
                    }
                }
            })
        
        # Update origins in config
        config['Origins'] = {
            'Quantity': len(new_origins),
            'Items': new_origins
        }
        
        # Update default cache behavior to use first origin
        config['DefaultCacheBehavior']['TargetOriginId'] = new_origins[0]['Id']
        
        # Update distribution
        logger.info(f"Updating distribution with {len(new_origins)} origins")
        cloudfront.update_distribution(
            Id=distribution_id,
            DistributionConfig=config,
            IfMatch=etag
        )
        
        logger.info(f"Successfully updated CloudFront distribution {distribution_id}")
        
    except Exception as e:
        logger.error(f"Error updating CloudFront distribution: {str(e)}")
        raise