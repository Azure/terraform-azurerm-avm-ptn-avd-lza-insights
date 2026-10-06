output "data_collection_rule_id" {
  description = "The ID of the Data Collection Rule deployed to the required location."
  value       = module.dcr.resource_id
}

output "data_collection_rule_location" {
  description = "The Azure region reported by the deployed Data Collection Rule."
  value       = data.azapi_resource.dcr.location
}
