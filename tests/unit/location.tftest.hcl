mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

run "uses_required_location_for_data_collection_rule" {
  command = plan

  variables {
    location  = "eastus2"
    name      = "microsoft-avdi-test"
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
    data_flows = [
      {
        destinations = ["workspace"]
        streams      = ["Microsoft-Perf"]
      }
    ]
    destinations = {
      log_analytics = [
        {
          name                  = "workspace"
          workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/workspace"
        }
      ]
    }
    enable_telemetry = false
  }

  assert {
    condition     = azapi_resource.this.location == var.location
    error_message = "The Data Collection Rule must use the required location."
  }
}
