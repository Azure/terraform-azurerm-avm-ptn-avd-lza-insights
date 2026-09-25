mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

run "uses_required_location_for_data_collection_rule" {
  command = plan

  variables {
    location                                         = "eastus2"
    monitor_data_collection_rule_name                = "microsoft-avdi-test"
    monitor_data_collection_rule_resource_group_name = "rg-test"
    monitor_data_collection_rule_data_flow = [
      {
        destinations = ["workspace"]
        streams      = ["Microsoft-Perf"]
      }
    ]
    monitor_data_collection_rule_destinations = {
      log_analytics = {
        name                  = "workspace"
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/workspace"
      }
    }
    enable_telemetry = false
  }

  assert {
    condition     = azurerm_monitor_data_collection_rule.this.location == var.location
    error_message = "The Data Collection Rule must use the required location."
  }
}
