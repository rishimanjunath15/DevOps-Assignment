output "frontend_url"        { value = module.apps.frontend_url }
output "backend_url"         { value = module.apps.backend_url }
output "acr_login_server"    { value = module.acr.login_server }
output "acr_registry_name"   { value = module.acr.registry_name }
output "resource_group_name" { value = module.apps.resource_group_name }
