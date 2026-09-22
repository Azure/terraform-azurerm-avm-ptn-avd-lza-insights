output "data_collection_rule_name" {
  description = "A unique name for the data collection rule under test."
  value       = "microsoft-avdi-upgrade-${random_string.suffix.result}"
}

output "location" {
  description = "The Azure region for the test resources."
  value       = var.location
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the destination Log Analytics workspace."
  value       = azapi_resource.log_analytics_workspace.id
}

output "resource_group_id" {
  description = "The resource ID of the test resource group."
  value       = azapi_resource.rg.id
}

output "resource_group_name" {
  description = "The name of the test resource group."
  value       = azapi_resource.rg.name
}
