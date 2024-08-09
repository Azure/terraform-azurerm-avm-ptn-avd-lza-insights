variable "avd_network_interface_name" {
  type        = string
  default     = "avd-nic-aad7-5"
  description = "The name of the network interface for the AVD VM session host."
}

variable "avd_vm_name" {
  type        = string
  default     = "vm-avdaad"
  description = "The name of the AVD VM session host."
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

variable "vm_count" {
  description = "Number of virtual machines to create"
  type        = number
  default     = 3
}
