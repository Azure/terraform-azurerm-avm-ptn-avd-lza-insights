# Upgrade test: deploys the rule with v0.2.0, the last AzureRM release, and
# then applies this AzAPI implementation to the same state. It proves the
# `moved` block adopts the existing rule instead of recreating it.
#
# Azure assigns a new immutable ID to every rule it creates, so an unchanged
# immutable ID proves the migration kept the original rule.

provider "azapi" {}

# v0.2.0 manages the rule with `azurerm_monitor_data_collection_rule`, so the
# legacy run needs AzureRM. It is migration input only; the migrated module
# declares no AzureRM resources.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

run "setup" {
  command   = apply
  state_key = "setup"

  module {
    source = "./tests/integration/setup"
  }
}

run "deploy_v0_2_0" {
  command   = apply
  state_key = "dcr"

  module {
    source  = "Azure/avm-ptn-avd-lza-insights/azurerm"
    version = "0.2.0"
  }

  variables {
    enable_telemetry                                 = false
    monitor_data_collection_rule_kind                = "Windows"
    monitor_data_collection_rule_location            = run.setup.location
    monitor_data_collection_rule_name                = run.setup.data_collection_rule_name
    monitor_data_collection_rule_resource_group_name = run.setup.resource_group_name
    monitor_data_collection_rule_data_flow = [
      {
        destinations = ["log-analytics"]
        streams      = ["Microsoft-Perf"]
      }
    ]
    monitor_data_collection_rule_data_sources = {
      performance_counter = [
        {
          counter_specifiers            = ["\\Processor(*)\\% Processor Time"]
          name                          = "perfCounters"
          sampling_frequency_in_seconds = 60
          streams                       = ["Microsoft-Perf"]
        }
      ]
    }
    monitor_data_collection_rule_destinations = {
      log_analytics = {
        name                  = "log-analytics"
        workspace_resource_id = run.setup.log_analytics_workspace_id
      }
    }
  }

  assert {
    condition     = startswith(output.resource.immutable_id, "dcr-")
    error_message = "v0.2.0 should create a data collection rule with an immutable ID."
  }
}

# A replacement makes `id` unknown during plan, which fails this assertion.
run "plan_migration" {
  command   = plan
  state_key = "dcr"

  variables {
    enable_telemetry = false
    kind             = "Windows"
    location         = run.setup.location
    name             = run.setup.data_collection_rule_name
    parent_id        = run.setup.resource_group_id
    data_flows = [
      {
        destinations = ["log-analytics"]
        streams      = ["Microsoft-Perf"]
      }
    ]
    data_sources = {
      performance_counters = [
        {
          counter_specifiers            = ["\\Processor(*)\\% Processor Time"]
          name                          = "perfCounters"
          sampling_frequency_in_seconds = 60
          streams                       = ["Microsoft-Perf"]
        }
      ]
    }
    destinations = {
      log_analytics = [
        {
          name                  = "log-analytics"
          workspace_resource_id = run.setup.log_analytics_workspace_id
        }
      ]
    }
  }

  assert {
    condition     = lower(azapi_resource.this.id) == lower(run.deploy_v0_2_0.resource.id)
    error_message = "The migration plan should adopt the v0.2.0 rule, not replace it."
  }
}

run "apply_migration" {
  command   = apply
  state_key = "dcr"

  variables {
    enable_telemetry = false
    kind             = "Windows"
    location         = run.setup.location
    name             = run.setup.data_collection_rule_name
    parent_id        = run.setup.resource_group_id
    data_flows = [
      {
        destinations = ["log-analytics"]
        streams      = ["Microsoft-Perf"]
      }
    ]
    data_sources = {
      performance_counters = [
        {
          counter_specifiers            = ["\\Processor(*)\\% Processor Time"]
          name                          = "perfCounters"
          sampling_frequency_in_seconds = 60
          streams                       = ["Microsoft-Perf"]
        }
      ]
    }
    destinations = {
      log_analytics = [
        {
          name                  = "log-analytics"
          workspace_resource_id = run.setup.log_analytics_workspace_id
        }
      ]
    }
  }

  assert {
    condition     = lower(output.resource_id) == lower(run.deploy_v0_2_0.resource.id)
    error_message = "The migrated rule should keep the v0.2.0 resource ID."
  }

  assert {
    condition     = output.rule_immutable_id == run.deploy_v0_2_0.resource.immutable_id
    error_message = "The migrated rule should keep the v0.2.0 immutable ID. A new ID means Azure recreated the rule."
  }

  assert {
    condition     = output.name == run.setup.data_collection_rule_name
    error_message = "The migrated rule should keep its name."
  }
}

# AzAPI marks `output` unknown whenever it plans any change to the rule's
# body, identity, tags, or type. An unknown `rule_immutable_id` fails this
# assertion, so the run passes only when the second plan is clean.
run "plan_after_migration" {
  command   = plan
  state_key = "dcr"

  variables {
    enable_telemetry = false
    kind             = "Windows"
    location         = run.setup.location
    name             = run.setup.data_collection_rule_name
    parent_id        = run.setup.resource_group_id
    data_flows = [
      {
        destinations = ["log-analytics"]
        streams      = ["Microsoft-Perf"]
      }
    ]
    data_sources = {
      performance_counters = [
        {
          counter_specifiers            = ["\\Processor(*)\\% Processor Time"]
          name                          = "perfCounters"
          sampling_frequency_in_seconds = 60
          streams                       = ["Microsoft-Perf"]
        }
      ]
    }
    destinations = {
      log_analytics = [
        {
          name                  = "log-analytics"
          workspace_resource_id = run.setup.log_analytics_workspace_id
        }
      ]
    }
  }

  assert {
    condition     = output.rule_immutable_id == run.deploy_v0_2_0.resource.immutable_id
    error_message = "The plan after migration should report no changes to the rule."
  }
}

# Changing `kind` must replace the rule. Replacement gives it a new immutable ID.
run "replace_on_kind_change" {
  command   = apply
  state_key = "dcr"

  variables {
    enable_telemetry = false
    kind             = "Linux"
    location         = run.setup.location
    name             = run.setup.data_collection_rule_name
    parent_id        = run.setup.resource_group_id
    data_flows = [
      {
        destinations = ["log-analytics"]
        streams      = ["Microsoft-Perf"]
      }
    ]
    data_sources = {
      performance_counters = [
        {
          counter_specifiers            = ["\\Processor(*)\\% Processor Time"]
          name                          = "perfCounters"
          sampling_frequency_in_seconds = 60
          streams                       = ["Microsoft-Perf"]
        }
      ]
    }
    destinations = {
      log_analytics = [
        {
          name                  = "log-analytics"
          workspace_resource_id = run.setup.log_analytics_workspace_id
        }
      ]
    }
  }

  assert {
    condition     = startswith(output.rule_immutable_id, "dcr-")
    error_message = "The replacement rule should have an immutable ID."
  }

  assert {
    condition     = output.rule_immutable_id != run.apply_migration.rule_immutable_id
    error_message = "Changing kind should replace the rule and give it a new immutable ID."
  }

  assert {
    condition     = lower(output.resource_id) == lower(run.apply_migration.resource_id)
    error_message = "The replacement rule should keep the same name and resource ID."
  }
}
