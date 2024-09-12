<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-ptn-avd-lza-insights

[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/Azure/terraform-azurerm-avm-ptn-avd-lza-insights.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-avm-ptn-avd-lza-insights "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/Azure/terraform-azurerm-avm-ptn-avd-lza-insights.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-avm-ptn-avd-lza-insights "Percentage of issues still open")

Azure Verified Module to deploy Azure Virtual Desktop Insights

Features
Data Collection Rules for Azure Virtual Desktop Insights

*This module has been tested and validated to work with version 4.0.0 of the azurerm provider and is backward compatible.*

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.6.6, < 2.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71.0, < 5.0.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.6.0, <4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_monitor_data_collection_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_monitor_data_collection_rule_data_flow"></a> [monitor\_data\_collection\_rule\_data\_flow](#input\_monitor\_data\_collection\_rule\_data\_flow)

Description: - `built_in_transform` - (Optional) The built-in transform to transform stream data.
- `destinations` - (Required) Specifies a list of destination names. A `azure_monitor_metrics` data source only allows for stream of kind `Microsoft-InsightsMetrics`.
- `output_stream` - (Optional) The output stream of the transform. Only required if the data flow changes data to a different stream.
- `streams` - (Required) Specifies a list of streams. Possible values include but not limited to `Microsoft-Event`, `Microsoft-InsightsMetrics`, `Microsoft-Perf`, `Microsoft-Syslog`, `Microsoft-WindowsEvent`, and `Microsoft-PrometheusMetrics`.
- `transform_kql` - (Optional) The KQL query to transform stream data.

Type:

```hcl
list(object({
    built_in_transform = optional(string)
    destinations       = list(string)
    output_stream      = optional(string)
    streams            = list(string)
    transform_kql      = optional(string)
  }))
```

### <a name="input_monitor_data_collection_rule_location"></a> [monitor\_data\_collection\_rule\_location](#input\_monitor\_data\_collection\_rule\_location)

Description: (Optional) The Azure Region where the Data Collection Rule should exist. Changing this forces a new Data Collection Rule to be created.

Type: `string`

### <a name="input_monitor_data_collection_rule_name"></a> [monitor\_data\_collection\_rule\_name](#input\_monitor\_data\_collection\_rule\_name)

Description: (Optional) The name which should be used for this Data Collection Rule. Changing this forces a new Data Collection Rule to be created.

Type: `string`

### <a name="input_monitor_data_collection_rule_resource_group_name"></a> [monitor\_data\_collection\_rule\_resource\_group\_name](#input\_monitor\_data\_collection\_rule\_resource\_group\_name)

Description: The name of the Resource Group where the Data Collection Rule should exist. Changing this forces a new Data Collection Rule to be created.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

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

Type:

```hcl
map(object({
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
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_lock"></a> [lock](#input\_lock)

Description:   Controls the Resource Lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description:   Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_monitor_data_collection_rule_association_data_collection_endpoint_id"></a> [monitor\_data\_collection\_rule\_association\_data\_collection\_endpoint\_id](#input\_monitor\_data\_collection\_rule\_association\_data\_collection\_endpoint\_id)

Description: (Optional) The ID of the Data Collection Endpoint which will be associated to the target resource.

Type: `string`

Default: `null`

### <a name="input_monitor_data_collection_rule_association_data_collection_rule_id"></a> [monitor\_data\_collection\_rule\_association\_data\_collection\_rule\_id](#input\_monitor\_data\_collection\_rule\_association\_data\_collection\_rule\_id)

Description: (Optional) The ID of the Data Collection Rule which will be associated to the target resource.

Type: `string`

Default: `null`

### <a name="input_monitor_data_collection_rule_association_description"></a> [monitor\_data\_collection\_rule\_association\_description](#input\_monitor\_data\_collection\_rule\_association\_description)

Description: (Optional) The description of the Data Collection Rule Association.

Type: `string`

Default: `null`

### <a name="input_monitor_data_collection_rule_association_name"></a> [monitor\_data\_collection\_rule\_association\_name](#input\_monitor\_data\_collection\_rule\_association\_name)

Description: (Optional) The name which should be used for this Data Collection Rule Association. Changing this forces a new Data Collection Rule Association to be created. Defaults to `configurationAccessEndpoint`.

Type: `string`

Default: `null`

### <a name="input_monitor_data_collection_rule_data_collection_endpoint_id"></a> [monitor\_data\_collection\_rule\_data\_collection\_endpoint\_id](#input\_monitor\_data\_collection\_rule\_data\_collection\_endpoint\_id)

Description: (Optional) The resource ID of the Data Collection Endpoint that this rule can be used with.

Type: `string`

Default: `null`

### <a name="input_monitor_data_collection_rule_data_sources"></a> [monitor\_data\_collection\_rule\_data\_sources](#input\_monitor\_data\_collection\_rule\_data\_sources)

Description:
---
`data_import` block supports the following:

---
`event_hub_data_source` block supports the following:
- `consumer_group` - (Optional) The Event Hub consumer group name.
- `name` - (Required) The name which should be used for this data source. This name should be unique across all data sources regardless of type within the Data Collection Rule.
- `stream` - (Required) The stream to collect from Event Hub. Possible value should be a custom stream name.

---
`extension` block supports the following:
- `extension_json` - (Optional) A JSON String which specifies the extension setting.
- `extension_name` - (Required) The name of the VM extension.
- `input_data_sources` - (Optional) Specifies a list of data sources this extension needs data from. An item should be a name of a supported data source which produces only one stream. Supported data sources type: `performance_counter`, `windows_event_log`,and `syslog`.
- `name` - (Required) The name which should be used for this data source. This name should be unique across all data sources regardless of type within the Data Collection Rule.
- `streams` - (Required) Specifies a list of streams that this data source will be sent to. A stream indicates what schema will be used for this data and usually what table in Log Analytics the data will be sent to. Possible values include but not limited to `Microsoft-Event`, `Microsoft-InsightsMetrics`, `Microsoft-Perf`, `Microsoft-Syslog`, `Microsoft-WindowsEvent`.

---
`iis_log` block supports the following:
- `log_directories` - (Optional) Specifies a list of absolute paths where the log files are located.
- `name` - (Required) The name which should be used for this data source. This name should be unique across all data sources regardless of type within the Data Collection Rule.
- `streams` - (Required) Specifies a list of streams that this data source will be sent to. A stream indicates what schema will be used for this data and usually what table in Log Analytics the data will be sent to. Possible value is `Microsoft-W3CIISLog`.

---
`log_file` block supports the following:
- `file_patterns` - (Required) Specifies a list of file patterns where the log files are located. For example, `C:\\JavaLogs\\*.log`.
- `format` - (Required) The data format of the log files. possible value is `text`.
- `name` - (Required) The name which should be used for this data source. This name should be unique across all data sources regardless of type within the Data Collection Rule.
- `streams` - (Required) Specifies a list of streams that this data source will be sent to. A stream indicates what schema will be used for this data and usually what table in Log Analytics the data will be sent to. Possible value should be custom stream names.

---
`settings` block supports the following:

---
`text` block supports the following:
- `record_start_timestamp_format` -

---
`performance_counter` block supports the following:
- `counter_specifiers` - (Required) Specifies a list of specifier names of the performance counters you want to collect. To get a list of performance counters on Windows, run the command `typeperf`. Please see [this document](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/data-sources-performance-counters#configure-performance-counters) for more information.
- `name` - (Required) The name which should be used for this data source. This name should be unique across all data sources regardless of type within the Data Collection Rule.
- `sampling_frequency_in_seconds` - (Required) The number of seconds between consecutive counter measurements (samples). The value should be integer between `1` and `300` inclusive. `sampling_frequency_in_seconds` must be equal to `60` seconds for counters collected with `Microsoft-InsightsMetrics` stream.
- `streams` - (Required) Specifies a list of streams that this data source will be sent to. A stream indicates what schema will be used for this data and usually what table in Log Analytics the data will be sent to. Possible values include but not limited to `Microsoft-InsightsMetrics`,and `Microsoft-Perf`.

---
`platform_telemetry` block supports the following:
- `name` - (Required) The name which should be used for this data source. This name should be unique across all data sources regardless of type within the Data Collection Rule.
- `streams` - (Required) Specifies a list of streams that this data source will be sent to. A stream indicates what schema will be used for this data and usually what table in Log Analytics the data will be sent to. Possible values include but not limited to `Microsoft.Cache/redis:Metrics-Group-All`.

---
`prometheus_forwarder` block supports the following:
- `name` - (Required) The name which should be used for this data source. This name should be unique across all data sources regardless of type within the Data Collection Rule.
- `streams` - (Required) Specifies a list of streams that this data source will be sent to. A stream indicates what schema will be used for this data and usually what table in Log Analytics the data will be sent to. Possible value is `Microsoft-PrometheusMetrics`.

---
`label_include_filter` block supports the following:
- `label` - (Required) The label of the filter. This label should be unique across all `label_include_fileter` block. Possible value is `microsoft_metrics_include_label`.
- `value` - (Required) The value of the filter.

---
`syslog` block supports the following:
- `facility_names` - (Required) Specifies a list of facility names. Use a wildcard `*` to collect logs for all facility names. Possible values are `auth`, `authpriv`, `cron`, `daemon`, `kern`, `lpr`, `mail`, `mark`, `news`, `syslog`, `user`, `uucp`, `local0`, `local1`, `local2`, `local3`, `local4`, `local5`, `local6`, `local7`,and `*`.
- `log_levels` - (Required) Specifies a list of log levels. Use a wildcard `*` to collect logs for all log levels. Possible values are `Debug`, `Info`, `Notice`, `Warning`, `Error`, `Critical`, `Alert`, `Emergency`,and `*`.
- `name` - (Required) The name which should be used for this data source. This name should be unique across all data sources regardless of type within the Data Collection Rule.
- `streams` - (Optional) Specifies a list of streams that this data source will be sent to. A stream indicates what schema will be used for this data and usually what table in Log Analytics the data will be sent to. Possible values include but not limited to `Microsoft-Syslog`,and `Microsoft-CiscoAsa`, and `Microsoft-CommonSecurityLog`.

---
`windows_event_log` block supports the following:
- `name` - (Required) The name which should be used for this data source. This name should be unique across all data sources regardless of type within the Data Collection Rule.
- `streams` - (Required) Specifies a list of streams that this data source will be sent to. A stream indicates what schema will be used for this data and usually what table in Log Analytics the data will be sent to. Possible values include but not limited to `Microsoft-Event`,and `Microsoft-WindowsEvent`, `Microsoft-RomeDetectionEvent`, and `Microsoft-SecurityEvent`.
- `x_path_queries` - (Required) Specifies a list of Windows Event Log queries in XPath expression. Please see [this document](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/data-collection-rule-azure-monitor-agent?tabs=cli#filter-events-using-xpath-queries) for more information.

---
`windows_firewall_log` block supports the following:
- `name` - (Required) The name which should be used for this data source. This name should be unique across all data sources regardless of type within the Data Collection Rule.
- `streams` - (Required) Specifies a list of streams that this data source will be sent to. A stream indicates what schema will be used for this data and usually what table in Log Analytics the data will be sent to.

Type:

```hcl
object({
    data_import = optional(object({
      event_hub_data_source = list(object({
        consumer_group = optional(string)
        name           = string
        stream         = string
      }))
    }))
    extension = optional(list(object({
      extension_json     = optional(string)
      extension_name     = string
      input_data_sources = optional(list(string))
      name               = string
      streams            = list(string)
    })))
    iis_log = optional(list(object({
      log_directories = optional(list(string))
      name            = string
      streams         = list(string)
    })))
    log_file = optional(list(object({
      file_patterns = list(string)
      format        = string
      name          = string
      streams       = list(string)
      settings = optional(object({
        text = object({
          record_start_timestamp_format = string
        })
      }))
    })))
    performance_counter = optional(list(object({
      counter_specifiers            = list(string)
      name                          = string
      sampling_frequency_in_seconds = number
      streams                       = list(string)
    })))
    platform_telemetry = optional(list(object({
      name    = string
      streams = list(string)
    })))
    prometheus_forwarder = optional(list(object({
      name    = string
      streams = list(string)
      label_include_filter = optional(set(object({
        label = string
        value = string
      })))
    })))
    syslog = optional(list(object({
      facility_names = list(string)
      log_levels     = list(string)
      name           = string
      streams        = optional(list(string))
    })))
    windows_event_log = optional(list(object({
      name           = string
      streams        = list(string)
      x_path_queries = list(string)
    })))
    windows_firewall_log = optional(list(object({
      name    = string
      streams = list(string)
    })))
  })
```

Default: `null`

### <a name="input_monitor_data_collection_rule_description"></a> [monitor\_data\_collection\_rule\_description](#input\_monitor\_data\_collection\_rule\_description)

Description: (Optional) The description of the Data Collection Rule.

Type: `string`

Default: `null`

### <a name="input_monitor_data_collection_rule_destinations"></a> [monitor\_data\_collection\_rule\_destinations](#input\_monitor\_data\_collection\_rule\_destinations)

Description:
---
`azure_monitor_metrics` block supports the following:
- `name` - (Optional) The name which should be used for this destination. This name should be unique across all destinations regardless of type within the Data Collection Rule.

---
`event_hub` block supports the following:
- `event_hub_id` - (Optional) The resource ID of the Event Hub.
- `name` - (Optional) The name which should be used for this destination. This name should be unique across all destinations regardless of type within the Data Collection Rule.

---
`event_hub_direct` block supports the following:
- `event_hub_id` - (Optional) The resource ID of the Event Hub.
- `name` - (Optional) The name which should be used for this destination. This name should be unique across all destinations regardless of type within the Data Collection Rule.

---
`log_analytics` block supports the following:
- `name` - (Optional) The name which should be used for this destination. This name should be unique across all destinations regardless of type within the Data Collection Rule.
- `workspace_resource_id` - (Optional) The ID of a Log Analytic Workspace resource.

---
`monitor_account` block supports the following:
- `monitor_account_id` - (Optional) The resource ID of the Monitor Account.
- `name` - (Optional) The name which should be used for this destination. This name should be unique across all destinations regardless of type within the Data Collection Rule.

---
`storage_blob` block supports the following:
- `container_name` - (Optional) The Storage Container name.
- `name` - (Optional) The name which should be used for this destination. This name should be unique across all destinations regardless of type within the Data Collection Rule.
- `storage_account_id` - (Optional) The resource ID of the Storage Account.

---
`storage_blob_direct` block supports the following:
- `container_name` - (Optional) The Storage Container name.
- `name` - (Optional) The name which should be used for this destination. This name should be unique across all destinations regardless of type within the Data Collection Rule.
- `storage_account_id` - (Optional) The resource ID of the Storage Account.

---
`storage_table_direct` block supports the following:
- `name` - (Optional) The name which should be used for this destination. This name should be unique across all destinations regardless of type within the Data Collection Rule.
- `storage_account_id` - (Optional) The resource ID of the Storage Account.
- `table_name` - (Optional) The Storage Table name.

Type:

```hcl
object({
    azure_monitor_metrics = optional(object({
      name = optional(string)
    }))
    event_hub = optional(object({
      event_hub_id = optional(string)
      name         = optional(string)
    }))
    event_hub_direct = optional(object({
      event_hub_id = optional(string)
      name         = optional(string)
    }))
    log_analytics = optional(object({
      name                  = optional(string)
      workspace_resource_id = optional(string)
    }))
    monitor_account = optional(list(object({
      monitor_account_id = optional(string)
      name               = optional(string)
    })))
    storage_blob = optional(list(object({
      container_name     = optional(string)
      name               = optional(string)
      storage_account_id = optional(string)
    })))
    storage_blob_direct = optional(list(object({
      container_name     = optional(string)
      name               = optional(string)
      storage_account_id = optional(string)
    })))
    storage_table_direct = optional(list(object({
      name               = optional(string)
      storage_account_id = optional(string)
      table_name         = optional(string)
    })))
  })
```

Default: `{}`

### <a name="input_monitor_data_collection_rule_identity"></a> [monitor\_data\_collection\_rule\_identity](#input\_monitor\_data\_collection\_rule\_identity)

Description: - `identity_ids` - (Optional) A list of User Assigned Managed Identity IDs to be assigned to this Data Collection Rule. Currently, up to 1 identity is supported.
- `type` - (Required) Specifies the type of Managed Service Identity that should be configured on this Data Collection Rule. Possible values are `SystemAssigned` and `UserAssigned`.

Type:

```hcl
object({
    identity_ids = optional(set(string))
    type         = string
  })
```

Default: `null`

### <a name="input_monitor_data_collection_rule_kind"></a> [monitor\_data\_collection\_rule\_kind](#input\_monitor\_data\_collection\_rule\_kind)

Description: (Optional) The kind of the Data Collection Rule. Possible values are `Linux`, `Windows`, `AgentDirectToStore` and `WorkspaceTransforms`. A rule of kind `Linux` does not allow for `windows_event_log` data sources. And a rule of kind `Windows` does not allow for `syslog` data sources. If kind is not specified, all kinds of data sources are allowed.

Type: `string`

Default: `null`

### <a name="input_monitor_data_collection_rule_stream_declaration"></a> [monitor\_data\_collection\_rule\_stream\_declaration](#input\_monitor\_data\_collection\_rule\_stream\_declaration)

Description: - `stream_name` - (Required) The name of the custom stream. This name should be unique across all `stream_declaration` blocks.

---
`column` block supports the following:
- `name` - (Required) The name of the column.
- `type` - (Required) The type of the column data. Possible values are `string`, `int`, `long`, `real`, `boolean`, `datetime`,and `dynamic`.

Type:

```hcl
set(object({
    stream_name = string
    column = list(object({
      name = string
      type = string
    }))
  }))
```

Default: `null`

### <a name="input_monitor_data_collection_rule_tags"></a> [monitor\_data\_collection\_rule\_tags](#input\_monitor\_data\_collection\_rule\_tags)

Description: (Optional) A mapping of tags which should be assigned to the Data Collection Rule.

Type: `map(string)`

Default: `null`

### <a name="input_monitor_data_collection_rule_timeouts"></a> [monitor\_data\_collection\_rule\_timeouts](#input\_monitor\_data\_collection\_rule\_timeouts)

Description: - `create` - (Defaults to 30 minutes) Used when creating the Data Collection Rule.
- `delete` - (Defaults to 30 minutes) Used when deleting the Data Collection Rule.
- `read` - (Defaults to 5 minutes) Used when retrieving the Data Collection Rule.
- `update` - (Defaults to 30 minutes) Used when updating the Data Collection Rule.

Type:

```hcl
object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
```

Default: `null`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:   A map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - The description of the role assignment.
  - `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - The condition which will be used to scope the role assignment.
  - `condition_version` - The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The full output for the Monitor Data Collection Rule.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The full output for the Monitor Data Collection Rule.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->