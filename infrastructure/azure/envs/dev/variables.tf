variable "project_name" { type = string }
variable "environment"  { type = string }
variable "location"     { type = string }
variable "acr_sku"      { type = string }
variable "image_tag"    { type = string }

variable "backend_cpu"        { type = number }
variable "backend_memory_gb"  { type = string }
variable "frontend_cpu"       { type = number }
variable "frontend_memory_gb" { type = string }

variable "min_replicas"                   { type = number }
variable "max_replicas"                   { type = number }
variable "enable_autoscaling"             { type = bool   }
variable "http_scale_concurrent_requests" { type = number }
variable "log_retention_days"             { type = number }
