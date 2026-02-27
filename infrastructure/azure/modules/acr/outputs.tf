output "login_server" {
  description = "ACR login server URL (e.g. dheedevopsdevacr.azurecr.io)"
  value       = azurerm_container_registry.main.login_server
}

output "admin_username" {
  description = "ACR admin username — used by Container Apps to pull images"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "admin_password" {
  description = "ACR admin password — stored as a Container Apps secret"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

output "resource_group_name" {
  value = azurerm_resource_group.acr.name
}

output "registry_name" {
  value = azurerm_container_registry.main.name
}
