# Create DCR for AVD resources
resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.insights_data_collection_rules
  body = {
    kind = var.kind
    properties = {
      dataCollectionEndpointId = var.data_collection_endpoint_id
      dataFlows                = local.data_flows
      dataSources              = local.data_sources
      description              = var.description
      destinations             = local.destinations
      streamDeclarations       = local.stream_declarations
    }
  }
  create_headers      = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers      = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes = length(var.ignore_body_changes.insights_data_collection_rules) > 0 ? var.ignore_body_changes.insights_data_collection_rules : null
  # Unset optional inputs are `null` in `body`. Without this the provider would
  # send them to Azure as explicit JSON nulls.
  ignore_null_property   = true
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = ["properties.endpoints", "properties.immutableId"]
  retry                  = var.retry
  tags                   = var.tags
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "identity" {
    for_each = local.identity_type == null ? [] : [local.identity_type]

    content {
      type         = identity.value
      identity_ids = local.has_user_assigned_identities ? var.managed_identities.user_assigned_resource_ids : null
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
