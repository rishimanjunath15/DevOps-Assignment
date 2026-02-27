variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region (e.g. centralindia)"
  type        = string
}

variable "log_retention_days" {
  description = "Log retention in days for Log Analytics workspace"
  type        = number
  default     = 30
}

# ── ACR credentials ───────────────────────────────────────────────────────────

variable "acr_login_server" {
  description = "ACR login server URL (e.g. dheedevopsdevacr.azurecr.io)"
  type        = string
}

variable "acr_admin_username" {
  description = "ACR admin username"
  type        = string
  sensitive   = true
}

variable "acr_admin_password" {
  description = "ACR admin password"
  type        = string
  sensitive   = true
}

variable "image_tag" {
  description = "Docker image tag to deploy (e.g. latest, v1.0.0)"
  type        = string
  default     = "latest"
}

# ── Container sizing ──────────────────────────────────────────────────────────
# Container Apps CPU is in vCPU units (0.25, 0.5, 0.75, 1.0, 1.25, ...)
# Memory must be at least 2x the CPU: 0.25 CPU -> 0.5Gi minimum

variable "backend_cpu" {
  description = "Backend container vCPU allocation (0.25, 0.5, 0.75, 1.0...)"
  type        = number
  default     = 0.25
}

variable "backend_memory_gb" {
  description = "Backend container memory in Gi (must be >= 2x cpu)"
  type        = string
  default     = "0.5"
}

variable "frontend_cpu" {
  description = "Frontend container vCPU allocation"
  type        = number
  default     = 0.25
}

variable "frontend_memory_gb" {
  description = "Frontend container memory in Gi"
  type        = string
  default     = "0.5"
}

# ── Scaling ───────────────────────────────────────────────────────────────────

variable "min_replicas" {
  description = <<-EOT
    Minimum replica count.
    Set to 0 for dev/staging: Container Apps scales to ZERO when idle (no cost).
    This is a key difference from AWS ECS which always keeps at least 1 task running.
    Set to 2 for prod to guarantee availability.
  EOT
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum replica count"
  type        = number
  default     = 2
}

variable "enable_autoscaling" {
  description = "Enable HTTP-based autoscaling via KEDA. Set false for dev (fixed replica count)."
  type        = bool
  default     = true
}

variable "http_scale_concurrent_requests" {
  description = "Number of concurrent HTTP requests per replica at which to scale out"
  type        = number
  default     = 10
}
