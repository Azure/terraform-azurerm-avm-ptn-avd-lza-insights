provider "azapi" {}

provider "azurerm" {
  features {}
}

data "azapi_client_config" "this" {}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  location               = var.location
  name                   = "rg-avd-location-${random_string.suffix.result}"
  parent_id              = "/subscriptions/${data.azapi_client_config.this.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2024-11-01"
  response_export_values = []
  tags                   = var.tags
}

resource "azapi_resource" "log_analytics_workspace" {
  location  = var.location
  name      = "law-avd-location-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.OperationalInsights/workspaces@2023-09-01"
  body = {
    properties = {
      retentionInDays = 30
      sku = {
        name = "PerGB2018"
      }
    }
  }
  response_export_values = []
  tags                   = var.tags
}

module "dcr" {
  source = "../../"

  location = var.location
  monitor_data_collection_rule_data_flow = [
    {
      destinations = ["workspace"]
      streams      = ["Microsoft-Perf"]
    }
  ]
  monitor_data_collection_rule_name                = "microsoft-avdi-${random_string.suffix.result}"
  monitor_data_collection_rule_resource_group_name = azapi_resource.resource_group.name
  enable_telemetry                                 = var.enable_telemetry
  monitor_data_collection_rule_data_sources = {
    performance_counter = [
      {
        counter_specifiers            = ["\\Processor(_Total)\\% Processor Time"]
        name                          = "processor-time"
        sampling_frequency_in_seconds = 60
        streams                       = ["Microsoft-Perf"]
      }
    ]
  }
  monitor_data_collection_rule_destinations = {
    log_analytics = {
      name                  = "workspace"
      workspace_resource_id = azapi_resource.log_analytics_workspace.id
    }
  }
  monitor_data_collection_rule_kind = "Windows"
}
