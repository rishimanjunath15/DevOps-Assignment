variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS tasks run"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks (not publicly accessible)"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to Fargate tasks. Set true in dev (no NAT) so tasks can pull ECR images. False in prod (NAT handles egress)."
  type        = bool
  default     = false
}

variable "task_subnet_ids" {
  description = "Subnet IDs where ECS tasks are placed. Use public subnets + assign_public_ip=true in dev (no NAT). Use private subnets in prod (NAT provides egress)."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB (ECS tasks only accept traffic from ALB)"
  type        = string
}

# ─── ECR ──────────────────────────────────────────────────────────────────────

variable "ecr_backend_url" {
  description = "ECR repository URL for the backend image"
  type        = string
}

variable "ecr_frontend_url" {
  description = "ECR repository URL for the frontend image"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

# ─── Backend service ──────────────────────────────────────────────────────────

variable "backend_port" {
  description = "Container port for the backend"
  type        = number
  default     = 8000
}

variable "backend_cpu" {
  description = "CPU units for the backend task (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memory (MB) for the backend task"
  type        = number
  default     = 512
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 1
}

variable "backend_target_group_arn" {
  description = "ALB target group ARN for the backend service"
  type        = string
}

variable "backend_url" {
  description = "Backend URL passed to frontend as NEXT_PUBLIC_API_URL"
  type        = string
}

# ─── Frontend service ─────────────────────────────────────────────────────────

variable "frontend_port" {
  description = "Container port for the frontend"
  type        = number
  default     = 3000
}

variable "frontend_cpu" {
  description = "CPU units for the frontend task"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory (MB) for the frontend task"
  type        = number
  default     = 512
}

variable "frontend_desired_count" {
  description = "Desired number of frontend tasks"
  type        = number
  default     = 1
}

variable "frontend_target_group_arn" {
  description = "ALB target group ARN for the frontend service"
  type        = string
}

# ─── Cluster settings ─────────────────────────────────────────────────────────

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights on the cluster"
  type        = bool
  default     = false
}

variable "use_spot" {
  description = "Use FARGATE_SPOT instead of FARGATE (cheaper but interruptible — dev/staging only)"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# ─── Auto Scaling ─────────────────────────────────────────────────────────────

variable "backend_min_capacity" {
  description = "Minimum number of backend tasks for auto scaling"
  type        = number
  default     = 1
}

variable "backend_max_capacity" {
  description = "Maximum number of backend tasks for auto scaling"
  type        = number
  default     = 4
}

variable "frontend_min_capacity" {
  description = "Minimum number of frontend tasks for auto scaling"
  type        = number
  default     = 1
}

variable "frontend_max_capacity" {
  description = "Maximum number of frontend tasks for auto scaling"
  type        = number
  default     = 4
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization (%) that triggers scale-out"
  type        = number
  default     = 70
}

variable "autoscaling_scale_in_threshold" {
  description = <<-EOT
    CPU % below which a scale-in is triggered (prod only).
    When > 0, target tracking's own scale-in is DISABLED (disable_scale_in=true)
    and a CloudWatch alarm fires after 15 consecutive minutes below this value,
    invoking a step scaling policy that removes 1 task.
    Set to 0 (default) to let target tracking handle scale-in automatically.
    Example: dev=0 (no autoscaling), staging=0 (target tracking), prod=30.
  EOT
  type        = number
  default     = 0
}

variable "autoscaling_memory_target" {
  description = "Target memory utilization (%) that triggers scale-out"
  type        = number
  default     = 70
}

# ─── Deployment Behaviour ─────────────────────────────────────────────

variable "deployment_minimum_healthy_percent" {
  description = "Minimum % of tasks that must stay healthy during deployment. dev=0 (fast), staging=50, prod=100 (zero-downtime)"
  type        = number
  default     = 50
}

variable "deployment_maximum_percent" {
  description = "Maximum % of tasks allowed during deployment (enables rolling). Default 200 = run 2× desired during rollout."
  type        = number
  default     = 200
}

# ─── Security ─────────────────────────────────────────────────────────────

variable "restrict_outbound_egress" {
  description = "When true (prod), ECS task SG egress is limited to HTTPS (443) and DNS (UDP 53). When false (dev/staging), all outbound is allowed."
  type        = bool
  default     = false
}

variable "enable_autoscaling" {
  description = "Enable Application Auto Scaling for ECS services. Disabled in dev (fixed 1 task), enabled in staging/prod."
  type        = bool
  default     = true
}
