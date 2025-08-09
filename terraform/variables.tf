# Variables for Nightscout AWS Deployment

## -------------------------------------------------------------------------------------------------------------------
## MAIN SETUP
## -------------------------------------------------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "resources_prefix_name" {
  description = "Prefix name for all the auto generated resources"
  type        = string
  default     = "nightscout-aws"
}


## -------------------------------------------------------------------------------------------------------------------
## Networking Module Variables
## -------------------------------------------------------------------------------------------------------------------
variable "enable_private_subnets" {
  description = "Enable private subnets and associated resources"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "retention_in_days" {
  description = "Specifies the number of days you want to retain log events."
  type        = number
  default     = 14
  validation {
    condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.retention_in_days)
    error_message = "RetentionInDays must be one of: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "traffic_type" {
  description = "The type of traffic to log."
  type        = string
  default     = "REJECT"
  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.traffic_type)
    error_message = "TrafficType must be one of: ACCEPT, REJECT, ALL."
  }
}
