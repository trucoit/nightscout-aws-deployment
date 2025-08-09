# EC2 resources for ECS cluster

## -------------------------------------------------------------------------------------------------------------------
## Data Sources
## -------------------------------------------------------------------------------------------------------------------


data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

## -------------------------------------------------------------------------------------------------------------------
## Launch Template
## -------------------------------------------------------------------------------------------------------------------
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.resources_prefix_name}-"

  # This will point to the latest AMI dynamically
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-launch-template.html#use-an-ssm-parameter-instead-of-an-ami-id
  image_id      = "resolve:ssm:/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
  
  instance_type = var.instance_types[0]

  vpc_security_group_ids = [aws_security_group.ecs.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name   = var.cluster_name
    log_group_name = var.log_group_name
    aws_region     = data.aws_region.current.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.resources_prefix_name}-ecs-instance"
    }
  }

  tags = {
    Name = "${var.resources_prefix_name}-launch-template"
  }
}

## -------------------------------------------------------------------------------------------------------------------
## Auto Scaling Group
## -------------------------------------------------------------------------------------------------------------------
resource "aws_autoscaling_group" "ecs" {
  name                      = "${var.resources_prefix_name}-asg"
  vpc_zone_identifier       = var.public_subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 300
  protect_from_scale_in     = true

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ecs.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type = override.value
        }
      }
    }

    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.resources_prefix_name}-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = false
  }
}

## -------------------------------------------------------------------------------------------------------------------
## Security Group
## -------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "ecs" {
  name_prefix = "${var.resources_prefix_name}-ecs-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.resources_prefix_name}-ecs-sg"
  }
}

## -------------------------------------------------------------------------------------------------------------------
## IAM Resources
## -------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_instance" {
  name = "${var.resources_prefix_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.resources_prefix_name}-ecs-instance-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.resources_prefix_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name

  tags = {
    Name = "${var.resources_prefix_name}-ecs-instance-profile"
  }
}