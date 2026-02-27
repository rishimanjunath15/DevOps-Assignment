# Variables for prod environment
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of 2 availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the 2 public subnets (ALB)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the 2 private subnets (ECS tasks)"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway"
  type        = bool
  default     = true
}

# ECR
variable "ecr_image_tag_mutability" {
  description = "Image tag mutability for ECR repositories"
  type        = string
  default     = "IMMUTABLE"
}

variable "ecr_max_image_count" {
  description = "Maximum number of tagged images to retain per repository"
  type        = number
  default     = 10
}

# ECS
variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "backend_cpu" {
  type    = number
  default = 512
}
variable "backend_memory" {
  type    = number
  default = 1024
}
variable "backend_desired_count" {
  type    = number
  default = 2
}
variable "frontend_cpu" {
  type    = number
  default = 512
}
variable "frontend_memory" {
  type    = number
  default = 1024
}
variable "frontend_desired_count" {
  type    = number
  default = 2
}
variable "enable_container_insights" {
  type    = bool
  default = true
}
variable "use_spot" {
  description = "Use FARGATE_SPOT — false for prod (reliability required)"
  type        = bool
  default     = false
}
variable "log_retention_days" {
  type    = number
  default = 30
}

# Auto Scaling
variable "backend_min_capacity" {
  description = "Minimum number of backend tasks"
  type        = number
  default     = 2
}
variable "backend_max_capacity" {
  description = "Maximum number of backend tasks"
  type        = number
  default     = 4
}
variable "frontend_min_capacity" {
  description = "Minimum number of frontend tasks"
  type        = number
  default     = 2
}
variable "frontend_max_capacity" {
  description = "Maximum number of frontend tasks"
  type        = number
  default     = 4
}
variable "autoscaling_cpu_target" {
  description = "Target CPU % for auto scaling"
  type        = number
  default     = 70
}
variable "autoscaling_memory_target" {
  description = "Target memory % for auto scaling"
  type        = number
  default     = 70
}

variable "enable_autoscaling" {
  description = "Enable ECS Auto Scaling"
  type        = bool
  default     = true
}
variable "restrict_outbound_egress" {
  description = "Restrict ECS task SG to HTTPS+DNS only (prod)"
  type        = bool
  default     = true
}
variable "deployment_minimum_healthy_percent" {
  description = "Min healthy % during ECS deployment. 100 = zero-downtime rolling deploy"
  type        = number
  default     = 100
}
variable "deployment_maximum_percent" {
  description = "Max % tasks during rolling deployment"
  type        = number
  default     = 200
}
variable "autoscaling_scale_in_threshold" {
  description = "CPU % for explicit scale-in alarm. prod=30: must stay below 30% for 15 min before scaling in"
  type        = number
  default     = 30
}