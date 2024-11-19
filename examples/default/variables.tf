variable "subscription_id" {
  type        = string
  description = "The subscription ID for the Azure account."
}

variable "avd_vm_name" {
  type        = string
  default     = "vm-avdaad"
  description = "Base name for the Azure Virtual Desktop VMs"
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Azure region where the resource should be deployed.  If null, the location will be inferred from the resource group location."
}

variable "log_analytics_workspace_name" {
  type        = string
  default     = "avd-log-analytics-workspace"
  description = "The name of the Log Analytics workspace for Azure Virtual Desktop."
}

variable "vm_count" {
  type        = number
  default     = 2
  description = "Number of virtual machines to create"
}
