# ECS resources

## -------------------------------------------------------------------------------------------------------------------
## Data Sources
## -------------------------------------------------------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

## -------------------------------------------------------------------------------------------------------------------
## ECS Cluster
## -------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.resources_prefix_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.resources_prefix_name}-cluster"
  }
}

## -------------------------------------------------------------------------------------------------------------------
## ECS Capacity Provider
## -------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_capacity_provider" "main" {
  name = "${var.resources_prefix_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = var.autoscaling_group_arn
    managed_termination_protection = "ENABLED"
    managed_draining               = "ENABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = var.target_capacity
    }
  }

  tags = {
    Name = "${var.resources_prefix_name}-capacity-provider"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}

## -------------------------------------------------------------------------------------------------------------------
## IAM Role for ECS Task
## -------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "task_role" {
  name = "${var.resources_prefix_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.resources_prefix_name}-task-role"
  }
}

resource "aws_iam_policy" "deny_all" {
  name = "${var.resources_prefix_name}-deny-all-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = "*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_deny_all" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.deny_all.arn
}

## -------------------------------------------------------------------------------------------------------------------
## Task Definition
## -------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.resources_prefix_name}-task"

  # CPU and Memory - In ECS EC2, we may not want to set them and use as much as we want from the EC2
  cpu                      = var.task_cpu != null ? var.task_cpu : null
  memory                   = var.task_memory != null ? var.task_memory : null

  network_mode             = "host"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"

  volume {
    name = "efs-volume"
    efs_volume_configuration {
      file_system_id = var.efs_file_system_id
      root_directory = "/"
    }
  }

  container_definitions = jsonencode([
    {
      name             = var.container_name
      image            = var.container_image
      essential        = true
      cpu              = 1024
      memoryReservation = 1024
      mountPoints = [
        {
          sourceVolume  = "efs-volume"
          containerPath = "/data"
          readOnly      = false
        }
      ]
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = var.container_environment
    }
  ])

  tags = {
    Name = "${var.resources_prefix_name}-task"
  }
}

## -------------------------------------------------------------------------------------------------------------------
## ECS Service
## -------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_service" "main" {
  name            = "${var.resources_prefix_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.service_desired_count

  # We can't ever allow 2 Tasks to run at the same time, as we are running the Database container
  # - Managed draining is enabled in for the Capacity Provider
  # - When ECS Instance receives SPOT termination notice, it will send the SIGTERM signal to all the containers
  # - https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-draining.html
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent = 100

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
  }

  tags = {
    Name = "${var.resources_prefix_name}-service"
  }
}