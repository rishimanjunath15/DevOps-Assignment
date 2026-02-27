terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
  required_version = ">= 1.3.0"

  backend "azurerm" {
    resource_group_name  = "dhee-devops-tfstate"
    storage_account_name = "dheedevopstfdev"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# ── ACR ───────────────────────────────────────────────────────────────────────
module "acr" {
  source = "../../modules/acr"

  project_name = var.project_name
  environment  = var.environment
  location     = var.location
  acr_sku      = var.acr_sku
}

# ── Container Apps ────────────────────────────────────────────────────────────
module "apps" {
  source = "../../modules/container_apps"

  project_name = var.project_name
  environment  = var.environment
  location     = var.location

  # ACR credentials from ACR module
  acr_login_server   = module.acr.login_server
  acr_admin_username = module.acr.admin_username
  acr_admin_password = module.acr.admin_password
  image_tag          = var.image_tag

  # Container sizing
  backend_cpu        = var.backend_cpu
  backend_memory_gb  = var.backend_memory_gb
  frontend_cpu       = var.frontend_cpu
  frontend_memory_gb = var.frontend_memory_gb

  # Scaling
  min_replicas                   = var.min_replicas
  max_replicas                   = var.max_replicas
  enable_autoscaling             = var.enable_autoscaling
  http_scale_concurrent_requests = var.http_scale_concurrent_requests

  # Logs
  log_retention_days = var.log_retention_days
}
