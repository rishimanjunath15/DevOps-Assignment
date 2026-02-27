# Bootstrap: Creates the Azure Storage Account and Blob Container used
# as the Terraform remote backend for all Azure environments.
#
# Run this ONCE before any environment apply:
#   cd infrastructure/azure/bootstrap
#   terraform init
#   terraform apply -var="environment=dev"
#
# Then use the output storage_account_name and container_name in each
# envs/<env>/backend.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "tfstate" {
  name     = "dhee-devops-tfstate"
  location = var.location

  tags = {
    Purpose = "Terraform state storage"
    Project = "dhee-devops"
  }
}

# One storage account per environment to isolate state
resource "azurerm_storage_account" "tfstate" {
  for_each = toset(var.environments)

  name                     = "dheedevopstf${each.key}"  # must be globally unique, lowercase, <=24 chars
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Enable versioning — allows recovery of accidentally deleted/corrupted state
  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Environment = each.key
    Purpose     = "Terraform state"
    Project     = "dhee-devops"
  }
}

resource "azurerm_storage_container" "tfstate" {
  for_each = toset(var.environments)

  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate[each.key].name
  container_access_type = "private"
}
