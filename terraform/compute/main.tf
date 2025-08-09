## -------------------------------------------------------------------------------------------------------------------
## Compute module
## -------------------------------------------------------------------------------------------------------------------

## -------------------------------------------------------------------------------------------------------------------
## Data Sources
## -------------------------------------------------------------------------------------------------------------------
data "aws_region" "current" {}

## -------------------------------------------------------------------------------------------------------------------
## Shared CloudWatch Log Group
## -------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/${var.resources_prefix_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.resources_prefix_name}-logs"
  }
}


## -------------------------------------------------------------------------------------------------------------------
## ECS Module
## -------------------------------------------------------------------------------------------------------------------
module "ecs" {
  source = "./ecs"

  resources_prefix_name = var.resources_prefix_name
  log_group_name        = aws_cloudwatch_log_group.main.name
  autoscaling_group_arn = module.ec2.autoscaling_group_arn


  # task_cpu              = var.task_cpu
  # task_memory           = var.task_memory
  target_capacity       = var.target_capacity
  service_desired_count = var.service_desired_count
  container_name        = var.container_name
  container_image       = var.container_image
  container_port        = var.container_port
  container_environment = var.container_environment
}


## -------------------------------------------------------------------------------------------------------------------
## EC2 Module
## -------------------------------------------------------------------------------------------------------------------
module "ec2" {
  source = "./ec2"

  vpc_id                = var.vpc_id
  public_subnet_ids     = var.public_subnet_ids
  resources_prefix_name = var.resources_prefix_name
  log_group_name        = aws_cloudwatch_log_group.main.name
  cluster_name          = module.ecs.ecs_cluster_name
  
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity
  instance_types       = var.instance_types
  container_port       = var.container_port
}
