#!/bin/bash

# Configure ECS
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config
echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config

# Install and configure CloudWatch agent
yum update -y
yum install -y amazon-cloudwatch-agent

# Create CloudWatch agent config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "ec2/messages/{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/ecs/ecs-agent.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "ec2/ecs-agent/{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/ecs/ecs-init.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "ec2/ecs-init/{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json