variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
  default     = "rg-avd-insights"
}

variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed.  If null, the location will be inferred from the resource group location."
  default     = "eastus"
}

variable "avd_vm_name" {
  type        = string
  description = "The name of the AVD VM session host."
  default     = "avd-vm-aad7-5"
}

variable "avd_network_interface_name" {
  type        = string
  description = "The name of the network interface for the AVD VM session host."
  default     = "avd-nic-aad7-5"
}
