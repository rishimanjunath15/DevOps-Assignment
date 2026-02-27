variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "acr_sku" {
  description = "ACR SKU: Basic (no geo-replication), Standard, Premium (geo-replication + advanced policies)"
  type        = string
  default     = "Basic"
}

variable "image_retention_days" {
  description = "Days to retain untagged images (requires Premium tier)"
  type        = number
  default     = 7
}
