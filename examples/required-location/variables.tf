variable "location" {
  type        = string
  default     = "eastus2"
  description = "The Azure region where the test resource group, workspace, and Data Collection Rule are deployed."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = { environment = "test" }
  description = "Tags for the temporary test resources."
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Whether to enable optional AVM usage telemetry for this isolated deployment test."
}
