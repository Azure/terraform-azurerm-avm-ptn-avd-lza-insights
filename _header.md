# terraform-azurerm-avm-ptn-avd-lza-insights

[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/Azure/terraform-azurerm-avm-ptn-avd-lza-insights.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-avm-ptn-avd-lza-insights "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/Azure/terraform-azurerm-avm-ptn-avd-lza-insights.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-avm-ptn-avd-lza-insights "Percentage of issues still open")

Azure Verified Module to deploy Azure Virtual Desktop Insights

Features
Data Collection Rules for Azure Virtual Desktop Insights

## Upgrading to v0.3.0

v0.3.0 replaces the AzureRM provider with the AzAPI provider, as required by the AVM specification. The module no longer declares `hashicorp/azurerm` at all, so it is no longer tied to a single AzureRM major version. This resolves the request in [#126](https://github.com/Azure/terraform-azurerm-avm-ptn-avd-lza-insights/issues/126).

This is a breaking change to the input and output surface. Your Data Collection Rule is **not** destroyed. The module ships a `moved` block, and the AzAPI provider rewrites the existing `azurerm_monitor_data_collection_rule.this` state entry in place.

### Before you upgrade

- Run `terraform plan` normally. Do **not** pass `-refresh=false` on the first plan after upgrading. The state move copies only the resource ID, name, parent ID, and type. Everything else is backfilled by the refresh that follows.
- Set `parent_id` to the resource group ID exactly as it is spelled inside the rule's own resource ID. AzAPI derives `parent_id` by truncating the resource ID as a plain string, with no case normalisation, and `parent_id` forces replacement. A differently cased ID plans a destroy and recreate.
- Confirm the plan reports **no changes** before applying. If it proposes a replacement, stop and open an issue.

### Renamed inputs

| Before v0.3.0 | v0.3.0 |
| --- | --- |
| `monitor_data_collection_rule_name` | `name` |
| `monitor_data_collection_rule_location` | `location` |
| `monitor_data_collection_rule_resource_group_name` (group **name**) | `parent_id` (group **resource ID**) |
| `monitor_data_collection_rule_data_flow` | `data_flows` |
| `monitor_data_collection_rule_data_sources` | `data_sources` |
| `monitor_data_collection_rule_destinations` | `destinations` |
| `monitor_data_collection_rule_description` | `description` |
| `monitor_data_collection_rule_kind` | `kind` |
| `monitor_data_collection_rule_data_collection_endpoint_id` | `data_collection_endpoint_id` |
| `monitor_data_collection_rule_stream_declaration` | `stream_declarations` |
| `monitor_data_collection_rule_identity` | `managed_identities` |
| `monitor_data_collection_rule_tags` | `tags` |
| `monitor_data_collection_rule_timeouts` | `timeouts` |
| `monitor_data_collection_rule_association_*` | removed — these four inputs were declared but never used |

`managed_identities` already existed in v0.2.0 with the same shape, but nothing consumed it. It is now the identity input, and setting it takes effect.

### Reshaped inputs

The nested attributes now follow the shape of the Azure Resource Manager schema, so what you write maps one to one onto what Azure stores.

Data sources are pluralised: `performance_counter` becomes `performance_counters`, `windows_event_log` becomes `windows_event_logs`, `iis_log` becomes `iis_logs`, `log_file` becomes `log_files`, `extension` becomes `extensions`, `data_import` becomes `data_imports`, and `windows_firewall_log` becomes `windows_firewall_logs`. `syslog`, `platform_telemetry`, and `prometheus_forwarder` keep their names.

Destinations that ARM models as arrays are now lists rather than single objects, and are renamed to match ARM: `log_analytics`, `event_hub` becomes `event_hubs`, `event_hub_direct` becomes `event_hubs_direct`, `monitor_account` becomes `monitoring_accounts`, `storage_blob` becomes `storage_accounts`, `storage_blob_direct` becomes `storage_blobs_direct`, and `storage_table_direct` becomes `storage_tables_direct`. `azure_monitor_metrics` stays a single object. `azure_data_explorer` and `microsoft_fabric` are new.

Three attributes changed type:

- `stream_declarations` is now a map keyed by stream name. The `stream_name` attribute is gone, because the key replaces it.
- `label_include_filter` on `prometheus_forwarder` is now `map(string)`, matching the ARM dictionary. It was a list of `{ label, value }` objects.
- `extension_json` on `extensions` is now `extension_settings`. It is still a JSON string, so pass the same `jsonencode(...)` value you passed before.

Every data source that supports it also gains `transform_kql`, data flows gain `capture_overflow`, and `windows_firewall_logs` gains `profile_filter`.

### Changed outputs

| Before v0.3.0 | v0.3.0 |
| --- | --- |
| `resource` (the whole provider object) | removed — see [TFFR2](https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs) |
| `resource_id` (returned the whole object, not an ID) | `resource_id` — now returns the resource ID string |

If you consumed `module.<name>.resource.id`, use `module.<name>.resource_id`. The module also now exposes `name`, `rule_immutable_id`, `logs_ingestion_endpoint`, `metrics_ingestion_endpoint`, and `system_assigned_mi_principal_id`.
