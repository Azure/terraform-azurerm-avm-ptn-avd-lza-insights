# terraform-azurerm-avm-ptn-avd-lza-insights

[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/Azure/terraform-azurerm-avm-ptn-avd-lza-insights.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-avm-ptn-avd-lza-insights "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/Azure/terraform-azurerm-avm-ptn-avd-lza-insights.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-avm-ptn-avd-lza-insights "Percentage of issues still open")

Azure Verified Module to deploy Azure Virtual Desktop Insights

Features
Data Collection Rules for Azure Virtual Desktop Insights

## Upgrading to v0.3.0

v0.3.0 replaces the AzureRM provider with the AzAPI provider, as required by the AVM specification. The module no longer declares `hashicorp/azurerm` at all, so it is no longer tied to a single AzureRM major version. This resolves the request in [#126](https://github.com/Azure/terraform-azurerm-avm-ptn-avd-lza-insights/issues/126).

This is a breaking change to the input and output surface. The module ships a `moved` block to transfer the existing `azurerm_monitor_data_collection_rule.this` state entry to AzAPI. Keep the same module address and equivalent resource settings when upgrading. The state move does not prevent replacement if you also change settings that require a new rule.

### Before you upgrade

- Back up the existing Terraform state before upgrading.
- Run `terraform init -upgrade`, then `terraform plan` normally. Do **not** pass `-refresh=false` on the first plan after upgrading. The state move copies only the resource ID, name, parent ID, and type. Everything else is backfilled by the refresh that follows.
- Set `parent_id` to the resource group ID exactly as it is spelled inside the rule's own resource ID. AzAPI derives `parent_id` by truncating the resource ID as a plain string, with no case normalisation, and `parent_id` forces replacement. A differently cased ID plans a destroy and recreate.
- Keep `name`, `location`, and `kind` unchanged during migration. Changing `kind` requires replacement, including setting it on a rule that previously omitted it.
- Confirm the plan proposes **no deletion or replacement of the rule** before applying. Output and state-address changes are expected. Review any in-place changes to the rule's settings before proceeding. If an equivalent configuration proposes replacement, stop and open an issue.
- After applying the migration, run another plan and confirm there are no remaining resource changes.

The integration test in `tests/integration/upgrade.tftest.hcl` runs this path against real Azure. It deploys a rule with v0.2.0 and then migrates the same state to this version. It checks that the rule keeps its resource ID and immutable ID and that the next plan has no changes. It also checks that changing `kind` afterwards replaces the rule.

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

The `event_hub`, `event_hub_direct`, and `log_analytics` destinations change from single objects to lists. The other renamed destinations were already lists. `azure_monitor_metrics` stays a single object. `azure_data_explorer` and `microsoft_fabric` are new.

The following paths are relative to the old and new destination inputs:

| Before v0.3.0 | v0.3.0 |
| --- | --- |
| `event_hub.event_hub_id` | `event_hubs[*].event_hub_resource_id` |
| `event_hub_direct.event_hub_id` | `event_hubs_direct[*].event_hub_resource_id` |
| `log_analytics.workspace_resource_id` | `log_analytics[*].workspace_resource_id` |
| `monitor_account[*].monitor_account_id` | `monitoring_accounts[*].account_resource_id` |
| `storage_blob[*].storage_account_id` | `storage_accounts[*].storage_account_resource_id` |
| `storage_blob_direct[*].storage_account_id` | `storage_blobs_direct[*].storage_account_resource_id` |
| `storage_table_direct[*].storage_account_id` | `storage_tables_direct[*].storage_account_resource_id` |

Keep each destination's `name`, `container_name`, and `table_name` where applicable. Keep the matching names in `data_flows[*].destinations` unchanged. Each configured destination above requires a valid resource ID. Missing IDs and IDs of the wrong resource type now fail input validation. Supplying an ID only under its legacy attribute name also fails validation.

For example, inside the caller's module block:

```hcl
# Before v0.3.0
monitor_data_collection_rule_destinations = {
  event_hub = {
    name         = "events"
    event_hub_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/monitoring/providers/Microsoft.EventHub/namespaces/logs/eventhubs/events"
  }
}
```

```hcl
# v0.3.0
destinations = {
  event_hubs = [{
    name                  = "events"
    event_hub_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/monitoring/providers/Microsoft.EventHub/namespaces/logs/eventhubs/events"
  }]
}
```

Additional nested changes:

- `data_sources.data_import.event_hub_data_source` was a list. Use the single object `data_sources.data_imports.event_hub` instead. Keep `consumer_group`, `name`, and `stream` on that object.
- `stream_declarations` is now a map keyed by stream name. Replace the old `column` attribute with `columns`. The old `stream_name` value becomes the map key.
- `label_include_filter` on `prometheus_forwarder` is now `map(string)`, matching the ARM dictionary. It was a list of `{ label, value }` objects.
- `extension_json` on `extensions` is now `extension_settings`. It is still a JSON string, so pass the same `jsonencode(...)` value you passed before.

For example, a custom stream changes as follows:

```hcl
# Before v0.3.0
monitor_data_collection_rule_stream_declaration = [{
  stream_name = "Custom-Events"
  column      = [{ name = "TimeGenerated", type = "datetime" }]
}]
```

```hcl
# v0.3.0
stream_declarations = {
  "Custom-Events" = {
    columns = [{ name = "TimeGenerated", type = "datetime" }]
  }
}
```

The managed identity input also changes shape:

| Before v0.3.0: `monitor_data_collection_rule_identity` | v0.3.0: `managed_identities` |
| --- | --- |
| `type = "SystemAssigned"` | `system_assigned = true` |
| `type = "UserAssigned"` with `identity_ids = [...]` | `user_assigned_resource_ids = [...]` |
| `null` | `{}` or omit the input |

Preserve the existing identity selection and IDs during migration. Enabling or changing an identity is a separate configuration change.

Every data source that supports it also gains `transform_kql`, data flows gain `capture_overflow`, and `windows_firewall_logs` gains `profile_filter`.

### Changed outputs

| Before v0.3.0 | v0.3.0 |
| --- | --- |
| `resource` (the whole provider object) | removed — see [TFFR2](https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs) |
| `resource_id` (returned the whole object, not an ID) | `resource_id` — now returns the resource ID string |

If you consumed `module.<name>.resource.id`, use `module.<name>.resource_id`. The module also now exposes `name`, `rule_immutable_id`, `logs_ingestion_endpoint`, `metrics_ingestion_endpoint`, and `system_assigned_mi_principal_id`.
