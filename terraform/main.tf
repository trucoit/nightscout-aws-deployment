# Main Terraform configuration for Nightscout AWS Deployment

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

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Networking Module
module "networking" {
  source = "./networking"

  # Pass all networking variables explicitly
  resources_prefix_name  = var.resources_prefix_name
  retention_in_days      = var.retention_in_days
  traffic_type           = var.traffic_type
  enable_flow_logs       = var.enable_flow_logs
  enable_private_subnets = var.enable_private_subnets
}
