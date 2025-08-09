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
├── terraform.tfvars           # Current variables file (optional, if you create it)
├── .terraform.lock.hcl        # Provider version lock file
├── README.md                  # This documentation
├── compute/                   # Compute module
├── storage/                   # Storage module
├── samples/                   # Sample configuration files
│   ├── backend.tf.example     # Example S3 backend configuration
│   └── terraform.tfvars.example # Example variables file
├── scripts/                   # Utility scripts
│   └── setup-s3-backend.sh    # Script to set up S3 backend
└── networking/                # Networking module
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
   terraform apply --auto-approve
   ```

### Option 2: S3 Backend (Recommended for Production)

1. **Create up S3 backend using the provided script:**
   ```bash
   cd terraform
   ./setup-s3-backend.sh <your-s3-backend-bucket> <your-s3-bucket-region>
   ```

3. **Create your variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your desired values
   ```

4. **Initialize and deploy:**
   ```bash
   terraform init \
      -backend-config="<your-s3-backend-bucket>" \
      -backend-config="<your-s3-bucket-region>" 
   terraform plan
   terraform apply
   ```

## Configuration Variables

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

## Cost Considerations

- **NAT Gateway**: ~$45/month + data processing charges (when `enable_private_subnets = true`)
- **VPC Flow Logs**: CloudWatch Logs storage and ingestion charges (when `enable_flow_logs = true`)
- **Elastic IP**: $0.005/hour when not attached to a running instance
- **S3 Backend**: Minimal S3 storage costs for state files

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
2. **Resource limits**: Check AWS service limits for VPCs, subnets, etc.
3. **Backend initialization**: If switching backends, use `terraform init -migrate-state`

### Getting Help

- Check the module-specific README files for detailed information
- Review Terraform plan output before applying
- Use `terraform validate` to check configuration syntax
