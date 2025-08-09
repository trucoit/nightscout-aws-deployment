# VPC Public-Private Setup - Terraform Module

This Terraform module creates a VPC with public and private subnets.

## Architecture

The module creates:
- 1 VPC with CIDR block 10.0.0.0/16
- 3 Public subnets (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24) across 3 availability zones
- 3 Private subnets (10.0.4.0/24, 10.0.5.0/24, 10.0.6.0/24) - optional
- Internet Gateway for public subnet internet access
- NAT Gateway for private subnet internet access - optional
- Route tables and associations
- VPC Flow Logs with CloudWatch integration - optional

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
| `public_subnet_1_id` | Public Subnet A ID |
| `public_subnet_2_id` | Public Subnet B ID |
| `public_subnet_3_id` | Public Subnet C ID |
| `private_subnet_1_id` | Private Subnet A ID (if enabled) |
| `private_subnet_2_id` | Private Subnet B ID (if enabled) |
| `private_subnet_3_id` | Private Subnet C ID (if enabled) |
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
