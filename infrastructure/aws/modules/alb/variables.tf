variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block — ALB egress is restricted to this range so backend port 8000 is never reachable from the internet"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs where the ALB is deployed"
  type        = list(string)
}

variable "frontend_port" {
  description = "Container port of the frontend service"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Container port of the backend service"
  type        = number
  default     = 8000
}

variable "enable_deletion_protection" {
  description = "Prevent accidental ALB deletion (enable for prod)"
  type        = bool
  default     = false
}
