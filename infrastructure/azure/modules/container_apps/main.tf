# Azure Container Apps module
#
# Creates:
# - Resource Group
# - Log Analytics Workspace (required by Container Apps Environment for logging)
# - Container Apps Environment (equivalent of ECS cluster + VPC in AWS)
# - Backend Container App  (internal-ingress, FastAPI on port 8000)
# - Frontend Container App (external-ingress, Next.js on port 3000)
#
# Key difference from AWS:
#   AWS requires explicit VPC, subnets, ALB, and security groups.
#   Azure Container Apps abstracts all networking — the Environment manages ingress
#   and provides built-in load balancing with no extra resources.
#
# Scaling difference:
#   AWS uses CloudWatch CPU metrics → ECS Auto Scaling policies.
#   Azure uses KEDA HTTP concurrent request scaler → Container Apps replicas.
#   Dev/staging: min_replicas=0 (scale to ZERO when idle — no cost when not used).
#   Prod: min_replicas=2 (same guarantee as AWS prod).

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

# ── Resource Group ────────────────────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# ── Log Analytics Workspace ───────────────────────────────────────────────────
# Container Apps Environment requires a Log Analytics workspace for log streaming.
# Equivalent of CloudWatch Log Groups in AWS.
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  sku               = "PerGB2018"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# ── Container Apps Environment ────────────────────────────────────────────────
# Equivalent of ECS cluster + VPC. Azure manages all networking and load balancing.
# All Container Apps in the same Environment share a virtual network internally.
resource "azurerm_container_app_environment" "main" {
  name                       = "${var.project_name}-${var.environment}-env"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# ── Backend Container App ─────────────────────────────────────────────────────
# FastAPI backend — port 8000.
# External ingress: needed because NEXT_PUBLIC_API_URL is a browser-side variable —
# the browser makes API calls directly to this URL.
# In a production app with server-side rendering or an API gateway, this could be
# internal-only. Documented in tradeoffs.
resource "azurerm_container_app" "backend" {
  name                         = "${var.environment}-backend"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  template {
    container {
      name   = "backend"
      image  = "${var.acr_login_server}/backend:${var.image_tag}"
      cpu    = var.backend_cpu
      memory = "${var.backend_memory_gb}Gi"
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    # HTTP-based autoscaling via KEDA
    # Scale out when concurrent requests per replica exceed the threshold.
    # This is natively appropriate for Container Apps — unlike AWS ECS which uses CPU.
    # The contrast is intentional: AWS = infrastructure metric (CPU), Azure = application metric (HTTP load).
    dynamic "http_scale_rule" {
      for_each = var.enable_autoscaling ? [1] : []
      content {
        name                = "http-scale"
        concurrent_requests = tostring(var.http_scale_concurrent_requests)
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # ACR credentials — Container Apps pulls from private registry using admin creds.
  # Production improvement: use managed identity pull (documented in "What We Did NOT Do").
  registry {
    server               = var.acr_login_server
    username             = var.acr_admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = var.acr_admin_password
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# ── Frontend Container App ────────────────────────────────────────────────────
# Next.js frontend — port 3000.
# NEXT_PUBLIC_API_URL is injected at runtime via environment variable.
# Since Container Apps injects env vars into the running process (server-side),
# Next.js SSR picks them up on each request. For client-side hydration, the
# frontend image must be rebuilt with the backend URL if NEXT_PUBLIC_* vars
# are used in browser code.
resource "azurerm_container_app" "frontend" {
  name                         = "${var.environment}-frontend"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  # Depends on backend so we can reference its FQDN
  depends_on = [azurerm_container_app.backend]

  template {
    container {
      name   = "frontend"
      image  = "${var.acr_login_server}/frontend:${var.image_tag}"
      cpu    = var.frontend_cpu
      memory = "${var.frontend_memory_gb}Gi"

      # Backend URL — injected into the container at runtime.
      # Note: NEXT_PUBLIC_* vars in browser bundles are baked at build time.
      # To correctly pass the backend URL to browser-side code, rebuild the
      # frontend image with NEXT_PUBLIC_API_URL set. See deployment notes.
      env {
        name  = "NEXT_PUBLIC_API_URL"
        value = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    dynamic "http_scale_rule" {
      for_each = var.enable_autoscaling ? [1] : []
      content {
        name                = "http-scale"
        concurrent_requests = tostring(var.http_scale_concurrent_requests)
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server               = var.acr_login_server
    username             = var.acr_admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = var.acr_admin_password
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
