terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  min = 0
  max = length(module.regions.regions) - 1
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name_unique
  location = module.regions.regions[random_integer.region_index.result].name
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "uai-avd-dcr"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

# Fetch the AVD Session Host VM ID
data "azurerm_virtual_machine" "this" {
  name                = var.avd_vm_name
  resource_group_name = var.avd_compute_resourcegroup
}

# Fetch the an existing log analytics workspace for AVD resources
data "azurerm_log_analytics_workspace" "existing" {
  name                = var.log_analytics_workspace_name_existing
  resource_group_name = var.log_analytics_workspace_resource_group_name != "" ? var.log_analytics_workspace_resource_group_name : azurerm_resource_group.this.name
}

# Create a new log analytics workspace for AVD resources if it doesn't exist
resource "azurerm_log_analytics_workspace" "this" {
  count               = local.create_workspace ? 1 : 0
  location            = azurerm_resource_group.this.location
  name                = var.log_analytics_workspace_name
  resource_group_name = azurerm_resource_group.this.name
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "insights" {
  source                                                      = "../../"
  enable_telemetry                                            = var.enable_telemetry
  location                                                    = azurerm_resource_group.this.location
  name                                                        = "microsoft-avdi-eastus"
  monitor_data_collection_rule_kind                           = "Windows" # This is required for AVD Insights to work
  monitor_data_collection_rule_location                       = azurerm_resource_group.this.location
  monitor_data_collection_rule_resource_group_name            = azurerm_resource_group.this.name
  monitor_data_collection_rule_association_target_resource_id = data.azurerm_virtual_machine.this.id
  monitor_data_collection_rule_data_flow = [
    {
      destinations = [azurerm_log_analytics_workspace.this[0].id]
      streams      = ["Microsoft-Perf", "Microsoft-Event"]
    }
  ]
  monitor_data_collection_rule_destinations = {
    log_analytics = {
      name                                        = try(one(azurerm_log_analytics_workspace.this).name, null)
      workspace_resource_id                       = try(one(azurerm_log_analytics_workspace.this).id, null)
      log_analytics_workspace_resource_group_name = azurerm_resource_group.this.name
    }
  }

  resource_group_name = azurerm_resource_group.this.name
  monitor_data_collection_rule_data_sources = {
    performance_counter = [
      {
        counter_specifiers            = ["\\LogicalDisk(C:)\\Avg. Disk Queue Length", "\\LogicalDisk(C:)\\Current Disk Queue Length", "\\Memory\\Available Mbytes", "\\Memory\\Page Faults/sec", "\\Memory\\Pages/sec", "\\Memory\\% Committed Bytes In Use", "\\PhysicalDisk(*)\\Avg. Disk Queue Length", "\\PhysicalDisk(*)\\Avg. Disk sec/Read", "\\PhysicalDisk(*)\\Avg. Disk sec/Transfer", "\\PhysicalDisk(*)\\Avg. Disk sec/Write", "\\Processor Information(_Total)\\% Processor Time", "\\User Input Delay per Process(*)\\Max Input Delay", "\\User Input Delay per Session(*)\\Max Input Delay", "\\RemoteFX Network(*)\\Current TCP RTT", "\\RemoteFX Network(*)\\Current UDP Bandwidth"]
        name                          = "perfCounterDataSource10"
        sampling_frequency_in_seconds = 30
        streams                       = ["Microsoft-Perf"]
      },
      {
        counter_specifiers            = ["\\LogicalDisk(C:)\\% Free Space", "\\LogicalDisk(C:)\\Avg. Disk sec/Transfer", "\\Terminal Services(*)\\Active Sessions", "\\Terminal Services(*)\\Inactive Sessions", "\\Terminal Services(*)\\Total Sessions"]
        name                          = "perfCounterDataSource30"
        sampling_frequency_in_seconds = 60
        streams                       = ["Microsoft-Perf"]
      }
    ],
    windows_event_log = [
      {
        name           = "eventLogsDataSource"
        streams        = ["Microsoft-Event"]
        x_path_queries = ["Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "System!*", "Microsoft-FSLogix-Apps/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "Application!*[System[(Level=2 or Level=3)]]", "Microsoft-FSLogix-Apps/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]"]
      }
    ]
  }
  target_resource_id = data.azurerm_virtual_machine.this.id
}

