output "frontend_url" {
  description = "Dev frontend URL (Azure Container Apps)"
  value       = module.apps.frontend_url
}

output "backend_url" {
  description = "Dev backend URL (Azure Container Apps)"
  value       = module.apps.backend_url
}

output "acr_login_server" {
  description = "ACR login server — use to push images: docker push <acr_login_server>/backend:latest"
  value       = module.acr.login_server
}

output "acr_registry_name" {
  value = module.acr.registry_name
}

output "resource_group_name" {
  value = module.apps.resource_group_name
}
