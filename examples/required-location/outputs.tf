output "data_collection_rule_id" {
  description = "The ID of the Data Collection Rule deployed to the required location."
  value       = module.dcr.resource.id
}

output "data_collection_rule_location" {
  description = "The Azure region reported by the deployed Data Collection Rule."
  value       = module.dcr.resource.location
}
