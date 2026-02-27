output "storage_account_names" {
  description = "Storage account names per environment — use in backend.tf"
  value       = { for k, v in azurerm_storage_account.tfstate : k => v.name }
}

output "resource_group_name" {
  value = azurerm_resource_group.tfstate.name
}
