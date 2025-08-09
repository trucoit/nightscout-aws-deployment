# VPC setup with public and private schema - Terraform version

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "pub_private_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.resources_prefix_name}-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.pub_private_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.resources_prefix_name}-public-subnet-A"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.pub_private_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.resources_prefix_name}-public-subnet-B"
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id                  = aws_vpc.pub_private_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[2]
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.resources_prefix_name}-public-subnet-C"
  }
}

# Private Subnets (conditional)
resource "aws_subnet" "private_subnet_1" {
  count                   = var.enable_private_subnets ? 1 : 0
  vpc_id                  = aws_vpc.pub_private_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.resources_prefix_name}-private-subnet-A"
  }
}

resource "aws_subnet" "private_subnet_2" {
  count                   = var.enable_private_subnets ? 1 : 0
  vpc_id                  = aws_vpc.pub_private_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.resources_prefix_name}-private-subnet-B"
  }
}

resource "aws_subnet" "private_subnet_3" {
  count                   = var.enable_private_subnets ? 1 : 0
  vpc_id                  = aws_vpc.pub_private_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[2]
  cidr_block              = "10.0.6.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.resources_prefix_name}-private-subnet-C"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.pub_private_vpc.id

  tags = {
    Name = "${var.resources_prefix_name}-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.pub_private_vpc.id

  tags = {
    Name = "${var.resources_prefix_name}-PublicRouteTable"
  }
}

# Public Route
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

# Public Subnet Route Table Associations
resource "aws_route_table_association" "public_subnet_1_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_3_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_3.id
  route_table_id = aws_route_table.public_route_table.id
}

# NAT Gateway EIP (conditional)
resource "aws_eip" "nat_public_ip" {
  count  = var.enable_private_subnets ? 1 : 0
  domain = "vpc"

  depends_on = [aws_vpc.pub_private_vpc]
}

# NAT Gateway (conditional)
resource "aws_nat_gateway" "nat_gateway" {
  count         = var.enable_private_subnets ? 1 : 0
  allocation_id = aws_eip.nat_public_ip[0].id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "${var.resources_prefix_name}-NatGateway"
  }
}

# Private Route Table (conditional)
resource "aws_route_table" "private_route_table" {
  count  = var.enable_private_subnets ? 1 : 0
  vpc_id = aws_vpc.pub_private_vpc.id

  tags = {
    Name = "${var.resources_prefix_name}-PrivateRouteTable"
  }
}

# Private Route (conditional)
resource "aws_route" "private_route" {
  count                  = var.enable_private_subnets ? 1 : 0
  route_table_id         = aws_route_table.private_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway[0].id
}

# Private Subnet Route Table Associations (conditional)
resource "aws_route_table_association" "private_subnet_1_route_table_association" {
  count          = var.enable_private_subnets ? 1 : 0
  subnet_id      = aws_subnet.private_subnet_1[0].id
  route_table_id = aws_route_table.private_route_table[0].id
}

resource "aws_route_table_association" "private_subnet_2_route_table_association" {
  count          = var.enable_private_subnets ? 1 : 0
  subnet_id      = aws_subnet.private_subnet_2[0].id
  route_table_id = aws_route_table.private_route_table[0].id
}

resource "aws_route_table_association" "private_subnet_3_route_table_association" {
  count          = var.enable_private_subnets ? 1 : 0
  subnet_id      = aws_subnet.private_subnet_3[0].id
  route_table_id = aws_route_table.private_route_table[0].id
}

# CloudWatch Log Group for VPC Flow Logs (conditional)
resource "aws_cloudwatch_log_group" "log_group" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/vpcflowlogs/${var.resources_prefix_name}"
  retention_in_days = var.retention_in_days
}

# IAM Role for VPC Flow Logs (conditional)
resource "aws_iam_role" "flow_logs_role" {
  count = var.enable_flow_logs ? 1 : 0

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for VPC Flow Logs (conditional)
resource "aws_iam_role_policy" "flow_logs_policy" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "flowlogs-policy"
  role  = aws_iam_role.flow_logs_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = aws_cloudwatch_log_group.log_group[0].arn
      }
    ]
  })
}

# VPC Flow Log (conditional)
resource "aws_flow_log" "flow_log" {
  count                = var.enable_flow_logs ? 1 : 0
  iam_role_arn         = aws_iam_role.flow_logs_role[0].arn
  log_destination      = aws_cloudwatch_log_group.log_group[0].arn
  log_destination_type = "cloud-watch-logs"
  vpc_id               = aws_vpc.pub_private_vpc.id
  traffic_type         = var.traffic_type
}
