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
## Storage Module
## -------------------------------------------------------------------------------------------------------------------
module "storage" {
  source = "../storage"

  resources_prefix_name   = var.resources_prefix_name
  vpc_id                  = var.vpc_id
  subnet_ids              = var.public_subnet_ids
  ec2_security_group_id   = module.ec2.security_group_id
}

## -------------------------------------------------------------------------------------------------------------------
## ECS Module
## -------------------------------------------------------------------------------------------------------------------
module "ecs" {
  source = "./ecs"

  resources_prefix_name = var.resources_prefix_name
  log_group_name        = aws_cloudwatch_log_group.main.name
  autoscaling_group_arn = module.ec2.autoscaling_group_arn
  efs_file_system_id    = module.storage.efs_file_system_id


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

## -------------------------------------------------------------------------------------------------------------------
## EC2 Helpers Module
## -------------------------------------------------------------------------------------------------------------------
module "ec2_helpers" {
  source = "./ec2/helpers"

  resources_prefix_name       = var.resources_prefix_name
  log_group_name              = aws_cloudwatch_log_group.main.name
  autoscaling_group_name      = module.ec2.autoscaling_group_name
  cloudfront_distribution_id  = var.cloudfront_distribution_id
  container_port              = var.container_port
  vpc_origin_id_alpha         = var.vpc_origin_alpha_id
  cf_origin_id_alpha          = var.cf_origin_alpha_id
}
