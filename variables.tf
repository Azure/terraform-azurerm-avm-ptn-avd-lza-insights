variable "data_flows" {
  type = list(object({
    built_in_transform = optional(string)
    capture_overflow   = optional(bool)
    destinations       = list(string)
    output_stream      = optional(string)
    streams            = list(string)
    transform_kql      = optional(string)
  }))
  description = <<DESCRIPTION
The data flows of the Data Collection Rule. Maps to `properties.dataFlows` in the ARM schema.

- `built_in_transform` - (Optional) The built-in transform to transform stream data.
- `capture_overflow` - (Optional) Whether overflowing data should be captured. Requires a `Microsoft-Overflow` destination.
- `destinations` - (Required) A list of destination names. Each name must match a `name` declared in `var.destinations`.
- `output_stream` - (Optional) The output stream of the transform. Only required when the data flow changes data to a different stream.
- `streams` - (Required) A list of streams. Possible values include but are not limited to `Microsoft-Event`, `Microsoft-InsightsMetrics`, `Microsoft-Perf`, `Microsoft-Syslog`, `Microsoft-WindowsEvent`, and `Microsoft-PrometheusMetrics`.
- `transform_kql` - (Optional) The KQL query used to transform stream data.
DESCRIPTION
  nullable    = false
}

variable "location" {
  type        = string
  description = "The Azure region where the Data Collection Rule will be deployed. Changing this forces a new resource to be created."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the Data Collection Rule. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = can(regex("^microsoft-avdi-", var.name))
    error_message = "The name must start with 'microsoft-avdi-'."
  }
}

variable "parent_id" {
  type        = string
  description = <<DESCRIPTION
The fully-qualified ARM resource ID of the existing resource group into which the Data Collection Rule will be deployed, for example `/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-avd-monitoring`.

This replaces the `monitor_data_collection_rule_resource_group_name` input used before v0.3.0. When migrating an existing deployment, supply the resource group ID exactly as it is spelled inside the rule's own resource ID, because `parent_id` forces replacement and is compared as a case-sensitive string.
DESCRIPTION
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid resource group resource ID."
  }
}

variable "data_collection_endpoint_id" {
  type        = string
  default     = null
  description = "(Optional) The resource ID of the Data Collection Endpoint that this rule can be used with. Maps to `properties.dataCollectionEndpointId`."

  validation {
    condition     = var.data_collection_endpoint_id == null ? true : can(provider::azapi::parse_resource_id("Microsoft.Insights/dataCollectionEndpoints", var.data_collection_endpoint_id))
    error_message = "`data_collection_endpoint_id` must be a valid Data Collection Endpoint resource ID."
  }
}

variable "data_sources" {
  type = object({
    data_imports = optional(object({
      event_hub = object({
        consumer_group = optional(string)
        name           = string
        stream         = string
      })
    }))
    extensions = optional(list(object({
      extension_name     = string
      extension_settings = optional(string)
      input_data_sources = optional(list(string))
      name               = string
      streams            = list(string)
    })))
    iis_logs = optional(list(object({
      log_directories = optional(list(string))
      name            = string
      streams         = list(string)
      transform_kql   = optional(string)
    })))
    log_files = optional(list(object({
      file_patterns = list(string)
      format        = string
      name          = string
      streams       = list(string)
      transform_kql = optional(string)
      settings = optional(object({
        text = object({
          record_start_timestamp_format = string
        })
      }))
    })))
    performance_counters = optional(list(object({
      counter_specifiers            = list(string)
      name                          = string
      sampling_frequency_in_seconds = number
      streams                       = list(string)
      transform_kql                 = optional(string)
    })))
    platform_telemetry = optional(list(object({
      name    = string
      streams = list(string)
    })))
    prometheus_forwarder = optional(list(object({
      label_include_filter = optional(map(string))
      name                 = string
      streams              = list(string)
    })))
    syslog = optional(list(object({
      facility_names = list(string)
      log_levels     = list(string)
      name           = string
      streams        = optional(list(string))
      transform_kql  = optional(string)
    })))
    windows_event_logs = optional(list(object({
      name           = string
      streams        = list(string)
      transform_kql  = optional(string)
      x_path_queries = list(string)
    })))
    windows_firewall_logs = optional(list(object({
      name           = string
      profile_filter = optional(list(string))
      streams        = list(string)
    })))
  })
  default     = null
  description = <<DESCRIPTION
The data sources of the Data Collection Rule. Maps to `properties.dataSources` in the ARM schema. Every data source `name` must be unique across all data source types within the rule.

---
`data_imports` supports the following:
- `event_hub` - (Required) The Event Hub to import data from. Maps to `dataSources.dataImports.eventHub`, which the ARM schema models as a single object rather than a list.
  - `consumer_group` - (Optional) The Event Hub consumer group name.
  - `name` - (Required) The name of this data source.
  - `stream` - (Required) The stream to collect from the Event Hub. The value should be a custom stream name.

---
`extensions` supports the following:
- `extension_name` - (Required) The name of the VM extension.
- `extension_settings` - (Optional) A JSON-encoded string holding the extension settings, for example `jsonencode({ workspaceId = "..." })`. It is decoded before being sent to Azure, so it arrives as a JSON object rather than a string.
- `input_data_sources` - (Optional) A list of data sources this extension needs data from. Each item must name a supported data source that produces exactly one stream. Supported types are `performance_counters`, `windows_event_logs`, and `syslog`.
- `name` - (Required) The name of this data source.
- `streams` - (Required) A list of streams that this data source will be sent to.

---
`iis_logs` supports the following:
- `log_directories` - (Optional) A list of absolute paths where the log files are located.
- `name` - (Required) The name of this data source.
- `streams` - (Required) A list of streams that this data source will be sent to. The supported value is `Microsoft-W3CIISLog`.
- `transform_kql` - (Optional) The KQL query used to transform this data source.

---
`log_files` supports the following:
- `file_patterns` - (Required) A list of file patterns where the log files are located, for example `C:\\JavaLogs\\*.log`.
- `format` - (Required) The data format of the log files. Possible values are `json` and `text`.
- `name` - (Required) The name of this data source.
- `settings` - (Optional) Additional settings for the log file.
  - `text.record_start_timestamp_format` - (Required) The timestamp format used to detect the start of a record.
- `streams` - (Required) A list of streams that this data source will be sent to. The values should be custom stream names.
- `transform_kql` - (Optional) The KQL query used to transform this data source.

---
`performance_counters` supports the following:
- `counter_specifiers` - (Required) A list of specifier names of the performance counters to collect. To list the performance counters available on Windows, run `typeperf`.
- `name` - (Required) The name of this data source.
- `sampling_frequency_in_seconds` - (Required) The number of seconds between consecutive samples. The value must be an integer between `1` and `300` inclusive. It must be `60` for counters collected with the `Microsoft-InsightsMetrics` stream.
- `streams` - (Required) A list of streams that this data source will be sent to. Possible values include but are not limited to `Microsoft-InsightsMetrics` and `Microsoft-Perf`.
- `transform_kql` - (Optional) The KQL query used to transform this data source.

---
`platform_telemetry` supports the following:
- `name` - (Required) The name of this data source.
- `streams` - (Required) A list of streams that this data source will be sent to, for example `Microsoft.Cache/redis:Metrics-Group-All`.

---
`prometheus_forwarder` supports the following:
- `label_include_filter` - (Optional) A map of label inclusion filters, where the map key is the label name and the map value is the label value. Only `microsoft_metrics_include_label` is currently supported, and values are matched case-insensitively. The ARM schema models this as a dictionary, so it is a map here rather than the list of label/value pairs used before v0.3.0.
- `name` - (Required) The name of this data source.
- `streams` - (Required) A list of streams that this data source will be sent to. The supported value is `Microsoft-PrometheusMetrics`.

---
`syslog` supports the following:
- `facility_names` - (Required) A list of facility names. Use `*` to collect logs for all facility names. Possible values are `auth`, `authpriv`, `cron`, `daemon`, `kern`, `lpr`, `mail`, `mark`, `news`, `syslog`, `user`, `uucp`, `local0` through `local7`, and `*`.
- `log_levels` - (Required) A list of log levels. Use `*` to collect logs for all log levels. Possible values are `Debug`, `Info`, `Notice`, `Warning`, `Error`, `Critical`, `Alert`, `Emergency`, and `*`.
- `name` - (Required) The name of this data source.
- `streams` - (Optional) A list of streams that this data source will be sent to. Possible values include but are not limited to `Microsoft-Syslog`, `Microsoft-CiscoAsa`, and `Microsoft-CommonSecurityLog`.
- `transform_kql` - (Optional) The KQL query used to transform this data source.

---
`windows_event_logs` supports the following:
- `name` - (Required) The name of this data source.
- `streams` - (Required) A list of streams that this data source will be sent to. Possible values include but are not limited to `Microsoft-Event`, `Microsoft-WindowsEvent`, `Microsoft-RomeDetectionEvent`, and `Microsoft-SecurityEvent`.
- `transform_kql` - (Optional) The KQL query used to transform this data source.
- `x_path_queries` - (Required) A list of Windows Event Log queries in XPath expression.

---
`windows_firewall_logs` supports the following:
- `name` - (Required) The name of this data source.
- `profile_filter` - (Optional) A list of firewall profiles to collect logs for.
- `streams` - (Required) A list of streams that this data source will be sent to.
DESCRIPTION
}

variable "description" {
  type        = string
  default     = null
  description = "(Optional) The description of the Data Collection Rule. Maps to `properties.description`."
}

variable "destinations" {
  type = object({
    azure_data_explorer = optional(list(object({
      database_name = optional(string)
      ingestion_uri = optional(string)
      name          = string
      resource_id   = optional(string)
    })))
    azure_monitor_metrics = optional(object({
      name = string
    }))
    event_hubs = optional(list(object({
      event_hub_resource_id = optional(string)
      name                  = string
    })))
    event_hubs_direct = optional(list(object({
      event_hub_resource_id = optional(string)
      name                  = string
    })))
    log_analytics = optional(list(object({
      name                  = string
      workspace_resource_id = optional(string)
    })))
    microsoft_fabric = optional(list(object({
      artifact_id   = optional(string)
      database_name = optional(string)
      ingestion_uri = optional(string)
      name          = string
      tenant_id     = optional(string)
    })))
    monitoring_accounts = optional(list(object({
      account_resource_id = optional(string)
      name                = string
    })))
    storage_accounts = optional(list(object({
      container_name              = optional(string)
      name                        = string
      storage_account_resource_id = optional(string)
    })))
    storage_blobs_direct = optional(list(object({
      container_name              = optional(string)
      name                        = string
      storage_account_resource_id = optional(string)
    })))
    storage_tables_direct = optional(list(object({
      name                        = string
      storage_account_resource_id = optional(string)
      table_name                  = optional(string)
    })))
  })
  default     = {}
  description = <<DESCRIPTION
The destinations of the Data Collection Rule. Maps to `properties.destinations` in the ARM schema. Every destination `name` must be unique across all destination types within the rule, and each name referenced by `var.data_flows[*].destinations` must appear here.

Before v0.3.0 the `event_hub`, `event_hub_direct`, and `log_analytics` destinations were single objects. The ARM schema models them as lists, so they are lists here. `storage_blob` is now `storage_accounts` and `monitor_account` is now `monitoring_accounts`, again matching ARM.

---
`azure_data_explorer` supports the following:
- `database_name` - (Optional) The Azure Data Explorer database to ingest into.
- `ingestion_uri` - (Optional) The ingestion URI of the cluster.
- `name` - (Required) The name of this destination.
- `resource_id` - (Optional) The resource ID of the Azure Data Explorer cluster.

---
`azure_monitor_metrics` supports the following:
- `name` - (Required) The name of this destination.

---
`event_hubs` supports the following:
- `event_hub_resource_id` - (Optional) The resource ID of the Event Hub.
- `name` - (Required) The name of this destination.

---
`event_hubs_direct` supports the following:
- `event_hub_resource_id` - (Optional) The resource ID of the Event Hub.
- `name` - (Required) The name of this destination.

---
`log_analytics` supports the following:
- `name` - (Required) The name of this destination.
- `workspace_resource_id` - (Optional) The resource ID of the Log Analytics workspace.

---
`microsoft_fabric` supports the following:
- `artifact_id` - (Optional) The artifact ID of the Microsoft Fabric eventhouse.
- `database_name` - (Optional) The Microsoft Fabric database to ingest into.
- `ingestion_uri` - (Optional) The ingestion URI of the eventhouse.
- `name` - (Required) The name of this destination.
- `tenant_id` - (Optional) The tenant ID of the Microsoft Fabric resource.

---
`monitoring_accounts` supports the following:
- `account_resource_id` - (Optional) The resource ID of the Monitor account.
- `name` - (Required) The name of this destination.

---
`storage_accounts` supports the following:
- `container_name` - (Optional) The storage container name.
- `name` - (Required) The name of this destination.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account.

---
`storage_blobs_direct` supports the following:
- `container_name` - (Optional) The storage container name.
- `name` - (Required) The name of this destination.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account.

---
`storage_tables_direct` supports the following:
- `name` - (Required) The name of this destination.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account.
- `table_name` - (Optional) The storage table name.
DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Data Collection Rule. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    insights_data_collection_rules = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths to ignore for each AzAPI resource declared by this module. Paths use dot notation, for example `properties.description`.

Changes to this variable take effect only after an apply, because the value is stored in provider-private state. Configuration at an ignored path is not sent to Azure until the path is removed from this list.

- `insights_data_collection_rules` - Paths ignored on the Data Collection Rule.
DESCRIPTION
  nullable    = false
}

variable "kind" {
  type        = string
  default     = null
  description = "(Optional) The kind of the Data Collection Rule. Possible values include `Linux`, `Windows`, `AgentDirectToStore`, and `WorkspaceTransforms`. A rule of kind `Linux` does not allow `windows_event_logs` data sources, and a rule of kind `Windows` does not allow `syslog` data sources. If not specified, all kinds of data sources are allowed."
}

# tflint-ignore: terraform_unused_declarations
variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

This replaces the `monitor_data_collection_rule_identity` input used before v0.3.0.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for id in var.managed_identities.user_assigned_resource_ids : can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", id))])
    error_message = "Each value in `user_assigned_resource_ids` must be a valid user assigned identity resource ID."
  }
}

variable "resource_types" {
  type = object({
    insights_data_collection_rules = optional(string, "Microsoft.Insights/dataCollectionRules@2024-03-11")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the module.

- `insights_data_collection_rules` - Resource type and API version for the Data Collection Rule.

The default matches the API version that the AzAPI provider selects when it moves state from `azurerm_monitor_data_collection_rule`, so a migrated deployment plans with no change to `type`.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to every supported AzAPI resource declared by the module. Defaults to `null` (no custom retry).

- `error_message_regex`  - (Optional) A list of regex patterns matching error messages that trigger a retry.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.

See <https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#retry> for full semantics.
DESCRIPTION
}

# tflint-ignore: terraform_unused_declarations
variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on the Data Collection Rule. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "stream_declarations" {
  type = map(object({
    columns = list(object({
      name = string
      type = string
    }))
  }))
  default     = null
  description = <<DESCRIPTION
Custom stream declarations for the Data Collection Rule. Maps to `properties.streamDeclarations` in the ARM schema.

The ARM schema models this as a dictionary keyed by stream name, so the map key is the stream name. Before v0.3.0 this was a set of objects carrying a `stream_name` attribute.

- `columns` - (Required) The list of columns used by data in this stream.
  - `name` - (Required) The name of the column.
  - `type` - (Required) The type of the column data. Possible values are `string`, `int`, `long`, `real`, `boolean`, `datetime`, `dynamic`, and `guid`.
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Default per-operation timeouts applied to every supported AzAPI resource declared by the module. Defaults to `null` (provider defaults). Each value is a Go duration string, for example `30m` or `1h`.

- `create` - (Optional) Timeout for create operations.
- `read`   - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.
- `delete` - (Optional) Timeout for delete operations.
DESCRIPTION
}
