variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Jenkins EC2 will be placed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where Jenkins EC2 will be placed (public subnet recommended)"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block (used for JNLP access from agents)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.micro" # 2 vCPU (1 guaranteed), 1GB RAM - Free Tier eligible
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30 # 30 GB sufficient for Jenkins + Docker images on t2.micro
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict in production (e.g., ["YOUR_IP/32"])
}

variable "enable_elastic_ip" {
  description = "Whether to attach an Elastic IP to Jenkins instance"
  type        = bool
  default     = true # Recommended for stable webhook endpoint
}
