# EFS Storage resources

## -------------------------------------------------------------------------------------------------------------------
## Data Sources
## -------------------------------------------------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

## -------------------------------------------------------------------------------------------------------------------
## Security Group for EFS
## -------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "efs" {
  name_prefix = "${var.resources_prefix_name}-efs-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.ec2_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.resources_prefix_name}-efs-sg"
  }
}

## -------------------------------------------------------------------------------------------------------------------
## EFS File System
## -------------------------------------------------------------------------------------------------------------------
resource "aws_efs_file_system" "main" {
  performance_mode                = "generalPurpose"
  throughput_mode                 = "elastic"
  encrypted                       = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = "${var.resources_prefix_name}-efs"
  }
}

## -------------------------------------------------------------------------------------------------------------------
## EFS Mount Targets (one per AZ)
## -------------------------------------------------------------------------------------------------------------------
resource "aws_efs_mount_target" "main" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

## -------------------------------------------------------------------------------------------------------------------
## EFS File System Policy (20GB limit)
## -------------------------------------------------------------------------------------------------------------------
resource "aws_efs_file_system_policy" "main" {
  file_system_id = aws_efs_file_system.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = "*"
        Action = "*"
        Resource = aws_efs_file_system.main.arn
        Condition = {
          NumericGreaterThan = {
            "elasticfilesystem:ClientWrite" = "21474836480" # 20GB in bytes
          }
        }
      }
    ]
  })
}