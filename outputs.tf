output "logs_ingestion_endpoint" {
  description = "The endpoint used to ingest logs into the Data Collection Rule."
  value       = try(azapi_resource.this.output.properties.endpoints.logsIngestion, null)
}

output "metrics_ingestion_endpoint" {
  description = "The endpoint used to ingest metrics into the Data Collection Rule."
  value       = try(azapi_resource.this.output.properties.endpoints.metricsIngestion, null)
}

output "name" {
  description = "The name of the Monitor Data Collection Rule."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "The resource ID of the Monitor Data Collection Rule."
  value       = azapi_resource.this.id
}

output "rule_immutable_id" {
  description = "The immutable ID that Azure assigned to the Monitor Data Collection Rule."
  value       = try(azapi_resource.this.output.properties.immutableId, null)
}

output "system_assigned_mi_principal_id" {
  description = "The principal ID of the system assigned managed identity, if one is enabled."
  value       = try(azapi_resource.this.identity[0].principal_id, null)
}
