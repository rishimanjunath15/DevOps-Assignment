# Variables for dev environment
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
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
  default     = false
}

# ECR
variable "ecr_image_tag_mutability" {
  description = "Image tag mutability for ECR repositories"
  type        = string
  default     = "MUTABLE"
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
  default = 256
}
variable "backend_memory" {
  type    = number
  default = 512
}
variable "backend_desired_count" {
  type    = number
  default = 1
}
variable "frontend_cpu" {
  type    = number
  default = 256
}
variable "frontend_memory" {
  type    = number
  default = 512
}
variable "frontend_desired_count" {
  type    = number
  default = 1
}
variable "enable_container_insights" {
  type    = bool
  default = false
}
variable "use_spot" {
  description = "Use FARGATE_SPOT (cheaper, dev/staging only)"
  type        = bool
  default     = true
}
variable "log_retention_days" {
  type    = number
  default = 7
}

# Auto Scaling
variable "backend_min_capacity" {
  description = "Minimum number of backend tasks"
  type        = number
  default     = 1
}
variable "backend_max_capacity" {
  description = "Maximum number of backend tasks"
  type        = number
  default     = 2
}
variable "frontend_min_capacity" {
  description = "Minimum number of frontend tasks"
  type        = number
  default     = 1
}
variable "frontend_max_capacity" {
  description = "Maximum number of frontend tasks"
  type        = number
  default     = 2
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
  description = "Enable ECS Auto Scaling (disabled in dev)"
  type        = bool
  default     = false
}
variable "restrict_outbound_egress" {
  description = "Restrict ECS task SG to HTTPS+DNS only (prod)"
  type        = bool
  default     = false
}
variable "deployment_minimum_healthy_percent" {
  description = "Min healthy % during ECS deployment. dev=0, staging=50, prod=100"
  type        = number
  default     = 0
}
variable "deployment_maximum_percent" {
  description = "Max % tasks during rolling deployment"
  type        = number
  default     = 200
}
variable "autoscaling_scale_in_threshold" {
  description = "CPU % for explicit scale-in alarm. 0 = disabled (dev has no autoscaling)"
  type        = number
  default     = 0
}
# Jenkins
variable "enable_jenkins" {
  description = "Whether to provision Jenkins EC2 instance"
  type        = bool
  default     = true
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.micro"
}

variable "jenkins_root_volume_size" {
  description = "Root volume size for Jenkins instance in GB"
  type        = number
  default     = 30
}

variable "jenkins_allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access to Jenkins"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "jenkins_enable_elastic_ip" {
  description = "Whether to attach Elastic IP to Jenkins"
  type        = bool
  default     = true
}