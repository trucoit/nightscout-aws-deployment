# Nightscout AWS Deployment - Terraform

This Terraform configuration deploys the infrastructure for Nightscout on AWS using a modular approach.

## Architecture

The deployment consists of:
- **Networking Module**: VPC with public and private subnets, Internet Gateway, NAT Gateway, and optional VPC Flow Logs

## Project Structure

```
terraform/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example variables file
├── backend.tf.example         # Example S3 backend configuration
├── setup-s3-backend.sh        # Script to set up S3 backend
├── README.md                  # This documentation
└── networking/                # Networking module
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars.example
    └── README.md
```

## Quick Start

### Option 1: Local State (Default)

1. **Navigate to the terraform directory:**
   ```bash
   cd terraform
   ```

2. **Create your variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your desired values
   ```

3. **Initialize and deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Option 2: S3 Backend (Recommended for Production)

1. **Set up S3 backend using the provided script:**
   ```bash
   cd terraform
   ./setup-s3-backend.sh my-terraform-state-bucket us-east-1
   ```

2. **Or manually set up S3 backend:**
   ```bash
   # Copy and edit the backend configuration
   cp backend.tf.example backend.tf
   # Edit backend.tf with your S3 bucket details
   ```

3. **Create your variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your desired values
   ```

4. **Initialize and deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Backend Configuration

### S3 Backend Setup

The S3 backend provides several advantages:
- **State Encryption**: Encrypts state files at rest
- **State Versioning**: Maintains history of state changes
- **Team Collaboration**: Shared state for multiple users

#### Automatic Setup (Recommended)

Use the provided script to automatically create the S3 bucket and configuration files:

```bash
./setup-s3-backend.sh your-bucket-name [region] [project-name]
```

This script will:
- Create an S3 bucket with versioning and encryption enabled
- Generate the `backend.tf` configuration file
- Generate the `terraform.tfvars` configuration file with your settings
- Configure proper security settings

Example:
```bash
./setup-s3-backend.sh nightscout-terraform-state us-east-1 nightscout-prod
```

#### Manual Setup

1. **Create S3 bucket:**
   ```bash
   # Create S3 bucket
   aws s3api create-bucket --bucket your-terraform-state-bucket --region us-east-1
   
   # Enable versioning
   aws s3api put-bucket-versioning --bucket your-terraform-state-bucket \
     --versioning-configuration Status=Enabled
   
   # Enable encryption
   aws s3api put-bucket-encryption --bucket your-terraform-state-bucket \
     --server-side-encryption-configuration '{
       "Rules": [
         {
           "ApplyServerSideEncryptionByDefault": {
             "SSEAlgorithm": "AES256"
           }
         }
       ]
     }'
   ```

2. **Copy and configure backend:**
   ```bash
   cp backend.tf.example backend.tf
   # Edit backend.tf with your bucket name and region
   ```

#### Migrating from Local to S3 Backend

If you already have local state and want to migrate to S3:

```bash
# After setting up S3 backend configuration
terraform init -migrate-state
```

## Configuration Variables

### Backend Configuration
| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `terraform_state_bucket` | S3 bucket name for state storage (false for local) | `string` | `false` | No |

### AWS Configuration
| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `aws_region` | AWS region for all resources | `string` | `"us-east-1"` | No |

### Networking Configuration
| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `resources_prefix_name` | Prefix name for all auto-generated resources | `string` | `"nightscout"` | No |
| `retention_in_days` | Number of days to retain VPC Flow Log events | `number` | `14` | No |
| `traffic_type` | Type of traffic to log (ACCEPT, REJECT, ALL) | `string` | `"REJECT"` | No |
| `enable_flow_logs` | Enable VPC Flow Logs | `bool` | `false` | No |
| `enable_private_subnets` | Enable private subnets and associated resources | `bool` | `true` | No |

## Example Configurations

### Development Environment (Local State)
```hcl
# terraform.tfvars
aws_region = "us-east-1"
resources_prefix_name = "nightscout-dev"
terraform_state_bucket = false  # Use local state
enable_private_subnets = false
enable_flow_logs = false
```

### Production Environment (S3 Backend)
```hcl
# terraform.tfvars
aws_region = "us-east-1"
resources_prefix_name = "nightscout-prod"
terraform_state_bucket = "my-terraform-state-bucket"  # Use S3 backend
enable_private_subnets = true
enable_flow_logs = true
traffic_type = "ALL"
retention_in_days = 90
```

## Outputs

After deployment, the following outputs will be available:

| Output | Description |
|--------|-------------|
| `aws_region` | AWS region used for deployment |
| `resources_prefix_name` | Prefix name used for all resources |
| `vpc_id` | VPC ID |
| `public_subnet_ids` | List of all public subnet IDs |
| `private_subnet_ids` | List of all private subnet IDs |
| `public_subnet_1_id` | Public Subnet A ID |
| `public_subnet_2_id` | Public Subnet B ID |
| `public_subnet_3_id` | Public Subnet C ID |
| `private_subnet_1_id` | Private Subnet A ID (if enabled) |
| `private_subnet_2_id` | Private Subnet B ID (if enabled) |
| `private_subnet_3_id` | Private Subnet C ID (if enabled) |
| `internet_gateway_id` | Internet Gateway ID |
| `nat_gateway_id` | NAT Gateway ID (if private subnets enabled) |
| `log_group_arn` | CloudWatch Log Group ARN (if flow logs enabled) |

## Using Outputs in Other Configurations

You can reference these outputs in other Terraform configurations or modules:

```hcl
# Example: Using VPC ID in another configuration
resource "aws_security_group" "example" {
  name   = "example-sg"
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
}
```

## Cost Considerations

- **NAT Gateway**: ~$45/month + data processing charges (when `enable_private_subnets = true`)
- **VPC Flow Logs**: CloudWatch Logs storage and ingestion charges (when `enable_flow_logs = true`)
- **Elastic IP**: $0.005/hour when not attached to a running instance
- **S3 Backend**: Minimal S3 storage costs for state files

## Adding More Modules

To extend this configuration with additional modules (e.g., compute, database, monitoring):

1. Create a new module directory under `terraform/`
2. Add the module call to `main.tf`
3. Add module variables to `variables.tf`
4. Add module outputs to `outputs.tf`

Example:
```hcl
# In main.tf
module "compute" {
  source = "./compute"
  
  vpc_id            = module.networking.pub_private_vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  # ... other variables
}
```

## Requirements

- Terraform >= 1.0
- AWS Provider >= 5.0
- AWS CLI configured with appropriate permissions

## Permissions Required

The AWS credentials used must have permissions to create:
- VPC and related networking resources
- IAM roles and policies (if flow logs enabled)
- CloudWatch Log Groups (if flow logs enabled)
- Elastic IPs and NAT Gateways (if private subnets enabled)
- S3 buckets (if using S3 backend)

## Troubleshooting

### Common Issues

1. **Insufficient permissions**: Ensure your AWS credentials have the required permissions
2. **Region availability**: Some regions may not have 3+ availability zones
3. **Resource limits**: Check AWS service limits for VPCs, subnets, etc.
4. **Backend initialization**: If switching backends, use `terraform init -migrate-state`

### Getting Help

- Check the module-specific README files for detailed information
- Review Terraform plan output before applying
- Use `terraform validate` to check configuration syntax
