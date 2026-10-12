mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Insights/dataCollectionRules/microsoft-avdi-test"
      identity = {
        principal_id = "11111111-1111-1111-1111-111111111111"
        tenant_id    = "22222222-2222-2222-2222-222222222222"
      }
      output = {
        properties = {
          immutableId = "dcr-test"
          endpoints = {
            logsIngestion    = "https://logs.example.invalid"
            metricsIngestion = "https://metrics.example.invalid"
          }
        }
      }
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}

variables {
  data_flows = [{
    destinations = ["workspace"]
    streams      = ["Microsoft-Perf"]
  }]
  location         = "eastus2"
  name             = "microsoft-avdi-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test"
  enable_telemetry = false
  destinations = {
    log_analytics = [{
      name                  = "workspace"
      workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.OperationalInsights/workspaces/logs"
    }]
  }
}

run "defaults_and_outputs" {
  command = apply

  assert {
    condition     = azapi_resource.this.replace_triggers_refs == tolist(["kind"])
    error_message = "The resource must declare replacement handling for kind."
  }
  assert {
    condition     = azapi_resource.this.ignore_null_property && local.data_sources == null && local.stream_declarations == null
    error_message = "Omitted optional body properties must remain null and be omitted from Azure requests."
  }
  assert {
    condition     = local.identity_type == null && try(length(azapi_resource.this.identity), 0) == 0
    error_message = "The module must not enable a managed identity by default."
  }
  assert {
    condition     = output.resource_id == azapi_resource.this.id && output.rule_immutable_id == "dcr-test"
    error_message = "The resource ID and immutable ID outputs must return individual strings."
  }
  assert {
    condition     = output.logs_ingestion_endpoint == "https://logs.example.invalid" && output.metrics_ingestion_endpoint == "https://metrics.example.invalid"
    error_message = "The ingestion endpoints must come from the exported Azure response."
  }
}

run "renamed_destinations" {
  command = apply

  variables {
    destinations = {
      azure_data_explorer = [{
        name        = "adx"
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Kusto/clusters/adx"
      }]
      event_hubs = [{
        name                  = "events"
        event_hub_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.EventHub/namespaces/ns/eventhubs/events"
      }]
      event_hubs_direct = [{
        name                  = "direct-events"
        event_hub_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.EventHub/namespaces/ns/eventhubs/direct"
      }]
      monitoring_accounts = [{
        name                = "monitor"
        account_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Monitor/accounts/monitor"
      }]
      storage_accounts = [{
        name                        = "blob"
        container_name              = "logs"
        storage_account_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/store"
      }]
      storage_blobs_direct = [{
        name                        = "direct-blob"
        container_name              = "logs"
        storage_account_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/store"
      }]
      storage_tables_direct = [{
        name                        = "direct-table"
        table_name                  = "logs"
        storage_account_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/store"
      }]
    }
  }

  assert {
    condition = (
      local.destinations.eventHubs[0].eventHubResourceId == var.destinations.event_hubs[0].event_hub_resource_id &&
      local.destinations.eventHubsDirect[0].eventHubResourceId == var.destinations.event_hubs_direct[0].event_hub_resource_id &&
      local.destinations.monitoringAccounts[0].accountResourceId == var.destinations.monitoring_accounts[0].account_resource_id &&
      local.destinations.storageAccounts[0].storageAccountResourceId == var.destinations.storage_accounts[0].storage_account_resource_id &&
      local.destinations.storageBlobsDirect[0].storageAccountResourceId == var.destinations.storage_blobs_direct[0].storage_account_resource_id &&
      local.destinations.storageTablesDirect[0].storageAccountResourceId == var.destinations.storage_tables_direct[0].storage_account_resource_id &&
      local.destinations.azureDataExplorer[0].resourceId == var.destinations.azure_data_explorer[0].resource_id
    )
    error_message = "Each renamed destination ID must reach its ARM body property unchanged."
  }
  assert {
    condition     = !contains(keys(local.destinations.azureDataExplorer[0]), "ingestionUri")
    error_message = "The read-only Azure Data Explorer ingestion URI must not be sent in the request."
  }
}

run "nested_sources_and_user_identity" {
  command = apply

  variables {
    kind = "Windows"
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/agent"]
    }
    data_sources = {
      data_imports = {
        event_hub = {
          name           = "import"
          stream         = "Custom-Events"
          consumer_group = "$Default"
        }
      }
      extensions = [
        {
          name               = "first"
          extension_name     = "first"
          streams            = ["Custom-Events"]
          extension_settings = "{\"enabled\":true}"
        },
        {
          name               = "second"
          extension_name     = "second"
          streams            = ["Custom-Events"]
          extension_settings = "{\"names\":[\"value\"]}"
        }
      ]
      prometheus_forwarder = [{
        name                 = "prometheus"
        streams              = ["Microsoft-PrometheusMetrics"]
        label_include_filter = { microsoft_metrics_include_label = "value" }
      }]
    }
    stream_declarations = {
      "Custom-Events" = {
        columns = [{ name = "TimeGenerated", type = "datetime" }]
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.kind == "Windows" && azapi_resource.this.identity[0].type == "UserAssigned"
    error_message = "The caller's kind and user-assigned identity must reach the resource."
  }
  assert {
    condition     = toset(azapi_resource.this.identity[0].identity_ids) == var.managed_identities.user_assigned_resource_ids
    error_message = "The caller's identity IDs must reach the resource unchanged."
  }
  assert {
    condition     = local.data_sources.dataImports.eventHub.consumerGroup == "$Default" && local.stream_declarations["Custom-Events"].columns[0].name == "TimeGenerated"
    error_message = "The Event Hub import object and stream columns must use the ARM structure."
  }
  assert {
    condition     = local.data_sources.extensions[0].extensionSettings.enabled && local.data_sources.extensions[1].extensionSettings.names[0] == "value"
    error_message = "Different extension JSON objects must retain their own types."
  }
  assert {
    condition     = local.data_sources.prometheusForwarder[0].labelIncludeFilter.microsoft_metrics_include_label == "value"
    error_message = "Prometheus label filters must retain their dictionary keys."
  }
}

run "system_identity" {
  command   = apply
  state_key = "system_identity"

  variables {
    managed_identities = { system_assigned = true }
  }

  assert {
    condition     = azapi_resource.this.identity[0].type == "SystemAssigned" && output.system_assigned_mi_principal_id == "11111111-1111-1111-1111-111111111111"
    error_message = "A system-assigned identity must expose its principal ID."
  }
}

run "reject_legacy_event_hub_id" {
  command = plan
  variables {
    destinations = { event_hubs = [{ name = "events", event_hub_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.EventHub/namespaces/ns/eventhubs/events" }] }
  }
  expect_failures = [var.destinations]
}

run "reject_legacy_direct_event_hub_id" {
  command = plan
  variables {
    destinations = { event_hubs_direct = [{ name = "events", event_hub_id = "legacy-id" }] }
  }
  expect_failures = [var.destinations]
}

run "reject_legacy_monitor_account_id" {
  command = plan
  variables {
    destinations = { monitoring_accounts = [{ name = "monitor", monitor_account_id = "legacy-id" }] }
  }
  expect_failures = [var.destinations]
}

run "reject_legacy_storage_account_id" {
  command = plan
  variables {
    destinations = { storage_accounts = [{ name = "blob", storage_account_id = "legacy-id" }] }
  }
  expect_failures = [var.destinations]
}

run "reject_legacy_direct_blob_id" {
  command = plan
  variables {
    destinations = { storage_blobs_direct = [{ name = "blob", storage_account_id = "legacy-id" }] }
  }
  expect_failures = [var.destinations]
}

run "reject_legacy_direct_table_id" {
  command = plan
  variables {
    destinations = { storage_tables_direct = [{ name = "table", storage_account_id = "legacy-id" }] }
  }
  expect_failures = [var.destinations]
}

run "reject_missing_workspace_id" {
  command = plan
  variables {
    destinations = { log_analytics = [{ name = "workspace" }] }
  }
  expect_failures = [var.destinations]
}

run "reject_wrong_resource_type" {
  command = plan
  variables {
    destinations = { log_analytics = [{ name = "workspace", workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/store" }] }
  }
  expect_failures = [var.destinations]
}

run "reject_malformed_adx_id" {
  command = plan
  variables {
    destinations = { azure_data_explorer = [{ name = "adx", resource_id = "not-a-resource-id" }] }
  }
  expect_failures = [var.destinations]
}

run "reject_missing_adx_id" {
  command = plan
  variables {
    destinations = { azure_data_explorer = [{ name = "adx", database_name = "logs" }] }
  }
  expect_failures = [var.destinations]
}
