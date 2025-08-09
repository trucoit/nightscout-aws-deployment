# VPC Public-Private Setup - Terraform Module

This Terraform module creates a VPC with public and private subnets.

## Architecture

The module creates:
- 1 VPC with CIDR block 10.0.0.0/16
- Public subnets across all available availability zones in the region (automatically calculated CIDR blocks)
- Private subnets across all available availability zones in the region - optional (automatically calculated CIDR blocks)
- Internet Gateway for public subnet internet access
- NAT Gateway for private subnet internet access - optional
- Route tables and associations
- VPC Flow Logs with CloudWatch integration - optional

**Note**: The number of subnets created depends on the number of availability zones in your AWS region. For example:
- us-east-1 (6 AZs): 6 public + 6 private subnets (if enabled)
- us-west-2 (4 AZs): 4 public + 4 private subnets (if enabled)
- ap-south-1 (3 AZs): 3 public + 3 private subnets (if enabled)

## Files

- `main.tf` - Main Terraform configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform.tfvars.example` - Example variables file

## Usage

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Create variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your desired values
   ```

3. **Plan the deployment:**
   ```bash
   terraform plan
   ```

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `resources_prefix_name` | Prefix name for all auto-generated resources | `string` | `"auto-networking"` | No |
| `retention_in_days` | Number of days to retain VPC Flow Log events | `number` | `14` | No |
| `traffic_type` | Type of traffic to log (ACCEPT, REJECT, ALL) | `string` | `"REJECT"` | No |
| `enable_flow_logs` | Enable VPC Flow Logs | `bool` | `false` | No |
| `enable_private_subnets` | Enable private subnets and associated resources | `bool` | `false` | No |

### Valid Values for `retention_in_days`
1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653

### Valid Values for `traffic_type`
- `ACCEPT` - Log accepted traffic
- `REJECT` - Log rejected traffic  
- `ALL` - Log all traffic

## Outputs

| Output | Description |
|--------|-------------|
| `pub_private_vpc_id` | VPC ID |
| `public_subnet_ids_by_az` | Map of public subnet IDs by availability zone |
| `private_subnet_ids_by_az` | Map of private subnet IDs by availability zone (if enabled) |
| `public_subnet_ids` | List of all public subnet IDs |
| `private_subnet_ids` | List of all private subnet IDs (if enabled) |
| `internet_gateway_id` | Internet Gateway ID |
| `nat_gateway_id` | NAT Gateway ID (if private subnets enabled) |
| `log_group_arn` | CloudWatch Log Group ARN (if flow logs enabled) |

## Examples

### Basic VPC with only public subnets:
```hcl
resources_prefix_name = "my-project"
enable_private_subnets = false
enable_flow_logs = false
```

### Full setup with private subnets and flow logs:
```hcl
resources_prefix_name = "production"
enable_private_subnets = true
enable_flow_logs = true
traffic_type = "ALL"
retention_in_days = 30
```

### Accessing specific subnet by AZ:
```hcl
# Reference a specific subnet by availability zone
subnet_id = module.networking.public_subnet_ids_by_az["us-west-2a"]

# Or get all subnet IDs as a list
all_public_subnets = module.networking.public_subnet_ids
```

## Cost Considerations

- **NAT Gateway**: Charges apply for data processing and hourly usage when `enable_private_subnets = true`
- **VPC Flow Logs**: CloudWatch Logs charges apply when `enable_flow_logs = true`
- **Elastic IP**: One EIP is allocated for the NAT Gateway when private subnets are enabled

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
