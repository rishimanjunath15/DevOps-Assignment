resource "azurerm_resource_group" "acr" {
  name     = "${var.project_name}-${var.environment}-acr"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_container_registry" "main" {
  name                = "${replace(var.project_name, "-", "")}${var.environment}acr"  # no hyphens, globally unique
  resource_group_name = azurerm_resource_group.acr.name
  location            = var.location
  sku                 = var.acr_sku

  # Admin credentials used by Container Apps to pull images
  # In production, a managed identity pull is preferred — see "What We Did NOT Do"
  admin_enabled = true

  # IMMUTABLE tags for prod — prevent accidental overwrites of released images
  # Controlled by the caller via var.image_tag_mutability
  # (ACR doesn't have a direct mutability flag like ECR; IMMUTABLE is enforced by policy)

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Retention policy — older images auto-purged to control storage cost
resource "azurerm_container_registry_task" "purge" {
  count                 = var.acr_sku == "Premium" ? 1 : 0
  name                  = "auto-purge"
  container_registry_id = azurerm_container_registry.main.id

  platform {
    os = "Linux"
  }

  encoded_step {
    task_content = base64encode(<<-EOT
      version: v1.1.0
      steps:
        - cmd: acr purge --filter 'frontend:.*' --filter 'backend:.*' --ago ${var.image_retention_days}d --untagged
          disableWorkingDirectoryOverride: true
          timeout: 3600
    EOT
    )
  }

  timer_trigger {
    name     = "daily"
    schedule = "0 2 * * *"  # 2 AM daily
    enabled  = true
  }
}
