# Preserves the state of deployments created with v0.2.0 and earlier, where the
# Data Collection Rule was managed by the AzureRM provider. The AzAPI provider
# implements cross-provider state moves for any `azurerm_*` source address, so
# Terraform rewrites the state entry in place instead of destroying the rule.
moved {
  from = azurerm_monitor_data_collection_rule.this
  to   = azapi_resource.this
}
