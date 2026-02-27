output "frontend_url" {
  description = "Public URL of the frontend Container App"
  value       = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
}

output "backend_url" {
  description = "Public URL of the backend Container App"
  value       = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
}

output "backend_fqdn" {
  description = "Backend FQDN (without scheme) — used for frontend NEXT_PUBLIC_API_URL"
  value       = azurerm_container_app.backend.ingress[0].fqdn
}

output "environment_id" {
  description = "Container Apps Environment ID"
  value       = azurerm_container_app_environment.main.id
}

output "resource_group_name" {
  description = "Resource group containing all Container Apps resources"
  value       = azurerm_resource_group.main.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}
