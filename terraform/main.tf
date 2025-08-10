# Main Terraform configuration for Nightscout AWS Deployment

## -------------------------------------------------------------------------------------------------------------------
## MAIN SETUP
## -------------------------------------------------------------------------------------------------------------------
## Terraform settings & provider configurations
## -------------------------------------------------------------------------------------------------------------------
##
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Backend remaining configuration will be set via backend.tf or terraform init -backend-config
  # See backend.tf.example for S3 backend configuration
  backend "s3" {
    key     = "nightscout/terraform.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}


## -------------------------------------------------------------------------------------------------------------------
## Networking
## -------------------------------------------------------------------------------------------------------------------
## Define Networking resources and configuration
## -------------------------------------------------------------------------------------------------------------------
module "networking" {
  source = "./networking"

  # Pass all networking variables explicitly
  resources_prefix_name  = var.resources_prefix_name
  retention_in_days      = var.retention_in_days
  traffic_type           = var.traffic_type
  enable_flow_logs       = var.enable_flow_logs
  enable_private_subnets = var.enable_private_subnets
}


## -------------------------------------------------------------------------------------------------------------------
## Compute
## -------------------------------------------------------------------------------------------------------------------
## Define Compute resources and configuration
## -------------------------------------------------------------------------------------------------------------------
module "compute" {
  source = "./compute"

  # Pass networking outputs
  vpc_id            = module.networking.pub_private_vpc_id
  public_subnet_ids = module.networking.public_subnet_ids

  # Pass common variables
  resources_prefix_name = var.resources_prefix_name
  container_port       = var.container_port

  # Pass routing outputs
  cloudfront_distribution_id = module.routing.cloudfront_distribution_id
  vpc_origin_id             = module.routing.vpc_origin_id
  cf_origin_id              = module.routing.cf_origin_id

  # Compute-specific variables can be overridden via terraform.tfvars
}

## -------------------------------------------------------------------------------------------------------------------
## Routing
## -------------------------------------------------------------------------------------------------------------------
## Define CloudFront distribution and routing configuration
## -------------------------------------------------------------------------------------------------------------------
module "routing" {
  source = "./routing"

  resources_prefix_name    = var.resources_prefix_name
  container_port          = var.container_port
  autoscaling_group_name  = module.compute.autoscaling_group_name
}

## -------------------------------------------------------------------------------------------------------------------
## Storage
## -------------------------------------------------------------------------------------------------------------------
## Define Storage resources and configuration
## -------------------------------------------------------------------------------------------------------------------
# TBD