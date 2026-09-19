terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}

provider "azapi" {}

data "azapi_client_config" "this" {}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"

  suffix = ["avd-monitoring"]
}

resource "azapi_resource" "rg" {
  location  = var.location
  name      = module.naming.resource_group.name
  parent_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
  tags      = local.tags
}

# The identity the data collection rule runs under. Passing it to the module
# exercises the `managed_identities` input.
resource "azapi_resource" "user_assigned_identity" {
  location  = var.location
  name      = "uai-avd-dcr"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  tags      = local.tags
}

resource "azapi_resource" "log_analytics_workspace" {
  location  = var.location
  name      = var.log_analytics_workspace_name
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.OperationalInsights/workspaces@2023-09-01"
  body = {
    properties = {
      retentionInDays = 30
      sku = {
        name = "PerGB2018"
      }
    }
  }
  tags = local.tags
}

# This is the module that creates the data collection rule
module "dcr" {
  source = "../../"

  data_flows = [
    {
      destinations = [var.log_analytics_workspace_name]
      streams      = ["Microsoft-Perf", "Microsoft-Event"]
    }
  ]
  location  = var.location
  name      = "microsoft-avdi-eastus"
  parent_id = azapi_resource.rg.id
  data_sources = {
    performance_counters = [
      {
        counter_specifiers            = ["\\LogicalDisk(C:)\\Avg. Disk Queue Length", "\\LogicalDisk(C:)\\Current Disk Queue Length", "\\Memory\\Available Mbytes", "\\Memory\\Page Faults/sec", "\\Memory\\Pages/sec", "\\Memory\\% Committed Bytes In Use", "\\PhysicalDisk(*)\\Avg. Disk Queue Length", "\\PhysicalDisk(*)\\Avg. Disk sec/Read", "\\PhysicalDisk(*)\\Avg. Disk sec/Transfer", "\\PhysicalDisk(*)\\Avg. Disk sec/Write", "\\Processor Information(_Total)\\% Processor Time", "\\User Input Delay per Process(*)\\Max Input Delay", "\\User Input Delay per Session(*)\\Max Input Delay", "\\RemoteFX Network(*)\\Current TCP RTT", "\\RemoteFX Network(*)\\Current UDP Bandwidth"]
        name                          = "perfCounterDataSource10"
        sampling_frequency_in_seconds = 30
        streams                       = ["Microsoft-Perf"]
      },
      {
        counter_specifiers            = ["\\LogicalDisk(C:)\\% Free Space", "\\LogicalDisk(C:)\\Avg. Disk sec/Transfer", "\\Terminal Services(*)\\Active Sessions", "\\Terminal Services(*)\\Inactive Sessions", "\\Terminal Services(*)\\Total Sessions"]
        name                          = "perfCounterDataSource30"
        sampling_frequency_in_seconds = 30
        streams                       = ["Microsoft-Perf"]
      }
    ]
    windows_event_logs = [
      {
        name           = "eventLogsDataSource"
        streams        = ["Microsoft-Event"]
        x_path_queries = ["Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "System!*", "Microsoft-FSLogix-Apps/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "Application!*[System[(Level=2 or Level=3)]]", "Microsoft-FSLogix-Apps/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]"]
      }
    ]
  }
  destinations = {
    log_analytics = [
      {
        name                  = var.log_analytics_workspace_name
        workspace_resource_id = azapi_resource.log_analytics_workspace.id
      }
    ]
  }
  enable_telemetry = var.enable_telemetry
  kind             = "Windows"
  managed_identities = {
    user_assigned_resource_ids = [azapi_resource.user_assigned_identity.id]
  }
  tags = local.tags
}
