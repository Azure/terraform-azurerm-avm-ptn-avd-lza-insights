# Supporting resources for the upgrade test. They live in their own test state
# so the data collection rule state holds only what the module manages.
data "azapi_client_config" "this" {}

resource "random_string" "suffix" {
  length  = 6
  numeric = true
  special = false
  upper   = false
}

resource "azapi_resource" "rg" {
  location  = var.location
  name      = "rg-avd-dcr-upgrade-${random_string.suffix.result}"
  parent_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
}

resource "azapi_resource" "log_analytics_workspace" {
  location  = var.location
  name      = "law-avd-dcr-upgrade-${random_string.suffix.result}"
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
}
