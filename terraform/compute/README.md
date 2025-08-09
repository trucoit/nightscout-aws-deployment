# Compute Module

This module creates an ECS cluster with EC2 capacity provider using spot instances for cost optimization.

## Resources Created

- **ECS Cluster** with Container Insights enabled
- **ECS Capacity Provider** with 100% target utilization
- **ECS Task Definition** using host networking mode
- **ECS Service** with 1 desired task
- **Auto Scaling Group** with spot instances only
- **Launch Template** with latest ECS-optimized AMI
- **Security Group** for ECS instances
- **IAM Role and Instance Profile** for ECS instances
- **CloudWatch Log Group** for container logs

## Key Features

- **Spot Instances Only**: 100% spot allocation for cost savings
- **Multi-AZ Deployment**: Spans across all available AZs
- **Instance Type Diversity**: Uses multiple instance types (2-4GB RAM) prioritized by cost
- **Dynamic AMI**: Automatically uses latest ECS-optimized AMI from SSM
- **Host Networking**: Task definition uses host networking mode
- **Auto Scaling**: Min=1, Desired=1, Max=2 instances

## Instance Types (Prioritized by Cost)

1. `t3.small` (2GB RAM) - Most cost-effective
2. `t3a.small` (2GB RAM) - AMD variant, cheaper
3. `t2.small` (2GB RAM) - Previous generation
4. `t3.medium` (4GB RAM)
5. `t3a.medium` (4GB RAM) - AMD variant
6. `t2.medium` (4GB RAM) - Previous generation

## Variables

See `variables.tf` for all configurable options. Key variables:

- `container_image`: Docker image to run (default: nginx:latest)
- `container_port`: Port exposed by container (default: 80)
- `target_capacity`: ECS capacity provider target utilization (default: 100)
- `instance_types`: List of EC2 instance types to use

## Usage

```hcl
module "compute" {
  source = "./compute"

  vpc_id            = module.networking.pub_private_vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  resources_prefix_name = var.resources_prefix_name

  # Optional overrides
  container_image = "your-app:latest"
  container_port  = 3000
}
```