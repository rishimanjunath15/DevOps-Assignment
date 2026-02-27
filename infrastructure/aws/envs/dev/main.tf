# Main configuration for dev environment
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─── VPC ─────────────────────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway # false for dev — saves cost
}

# ─── ECR ──────────────────────────────────────────────────────────────────────
module "ecr" {
  source = "../../modules/ecr"

  project_name         = var.project_name
  environment          = var.environment
  image_tag_mutability = var.ecr_image_tag_mutability
  max_image_count      = var.ecr_max_image_count
}

# ─── ALB ─────────────────────────────────────────────────────────────────────
module "alb" {
  source = "../../modules/alb"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  public_subnet_ids  = module.vpc.public_subnet_ids
  frontend_port      = 3000
  backend_port       = 8000
  enable_deletion_protection = false
}

# ─── ECS ─────────────────────────────────────────────────────────────────────
# NOTE: depends on module.alb — apply after ALB is created (Step 9)
module "ecs" {
  source = "../../modules/ecs"

  project_name   = var.project_name
  environment    = var.environment
  aws_region     = var.aws_region

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  # dev has no NAT — use public subnets + public IP so tasks can pull ECR images
  task_subnet_ids    = module.vpc.public_subnet_ids
  assign_public_ip   = true

  ecr_backend_url  = module.ecr.backend_url
  ecr_frontend_url = module.ecr.frontend_url
  image_tag        = var.image_tag

  alb_security_group_id     = module.alb.alb_security_group_id
  backend_target_group_arn  = module.alb.backend_target_group_arn
  frontend_target_group_arn = module.alb.frontend_target_group_arn
  backend_url               = "http://${module.alb.alb_dns_name}"

  backend_cpu           = var.backend_cpu
  backend_memory        = var.backend_memory
  backend_desired_count = var.backend_desired_count
  frontend_cpu          = var.frontend_cpu
  frontend_memory       = var.frontend_memory
  frontend_desired_count = var.frontend_desired_count

  enable_container_insights = var.enable_container_insights
  use_spot                  = var.use_spot
  log_retention_days        = var.log_retention_days

  backend_min_capacity     = var.backend_min_capacity
  backend_max_capacity     = var.backend_max_capacity
  frontend_min_capacity    = var.frontend_min_capacity
  frontend_max_capacity    = var.frontend_max_capacity
  autoscaling_cpu_target   = var.autoscaling_cpu_target
  autoscaling_memory_target = var.autoscaling_memory_target

  enable_autoscaling               = var.enable_autoscaling
  restrict_outbound_egress         = var.restrict_outbound_egress
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  autoscaling_scale_in_threshold   = var.autoscaling_scale_in_threshold
}

# ─── Jenkins EC2 (CI/CD Pipeline) ───────────────────────────────────────────
# Provisions a dedicated Jenkins server for automated builds and deployments
module "jenkins_ec2" {
  count  = var.enable_jenkins ? 1 : 0
  source = "../../modules/jenkins_ec2"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  subnet_id          = module.vpc.public_subnet_ids[0]
  vpc_cidr_block     = var.vpc_cidr
  instance_type      = var.jenkins_instance_type
  root_volume_size   = var.jenkins_root_volume_size
  allowed_ssh_cidr_blocks = var.jenkins_allowed_ssh_cidr
  enable_elastic_ip  = var.jenkins_enable_elastic_ip
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "ecr_frontend_url" {
  value = module.ecr.frontend_url
}

output "ecr_backend_url" {
  value = module.ecr.backend_url
}

output "alb_dns_name" {
  description = "Load balancer URL — open this in your browser"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

# ─── Jenkins Outputs ────────────────────────────────────────────────────────
output "jenkins_instance_id" {
  description = "Jenkins EC2 instance ID"
  value       = try(module.jenkins_ec2[0].instance_id, null)
}

output "jenkins_public_ip" {
  description = "Jenkins EC2 public IP (or Elastic IP if enabled)"
  value       = try(module.jenkins_ec2[0].elastic_ip, null)
}

output "jenkins_url" {
  description = "Jenkins web UI URL - access this in your browser"
  value       = try(module.jenkins_ec2[0].jenkins_url, null)
}

output "jenkins_security_group_id" {
  description = "Security group ID for Jenkins"
  value       = try(module.jenkins_ec2[0].security_group_id, null)
}
