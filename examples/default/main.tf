terraform {
  required_version = ">= 1.9.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}


# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
  suffix  = ["avd-monitoring"]
}

resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uai-avd-dcr"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_virtual_network" "this_vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this_subnet_1" {
  address_prefixes     = ["10.0.1.0/24"]
  name                 = "${module.naming.subnet.name_unique}-1"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this_vnet.name
}

# Create Azure Log Analytics workspace for Azure Virtual Desktop
resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = var.log_analytics_workspace_name
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
}

resource "azurerm_network_interface" "this" {
  count = var.vm_count

  location            = azurerm_resource_group.this.location
  name                = "${var.avd_vm_name}-${count.index}-nic"
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.this_subnet_1.id
  }
}

# Generate VM local password
resource "random_password" "vmpass" {
  length  = 20
  special = true
}

resource "azurerm_windows_virtual_machine" "this" {
  count = var.vm_count

  admin_password             = random_password.vmpass.result
  admin_username             = "adminuser"
  location                   = azurerm_resource_group.this.location
  name                       = "${var.avd_vm_name}-${count.index}"
  network_interface_ids      = [azurerm_network_interface.this[count.index].id]
  resource_group_name        = azurerm_resource_group.this.name
  size                       = "Standard_D4s_v4"
  computer_name              = "${var.avd_vm_name}-${count.index}"
  encryption_at_host_enabled = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    name                 = "${var.avd_vm_name}-${count.index}-osdisk"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }
  source_image_reference {
    offer     = "windows-11"
    publisher = "microsoftwindowsdesktop"
    sku       = "win11-23h2-avd"
    version   = "latest"
  }
}

# Virtual Machine Extension for AMA agent
resource "azurerm_virtual_machine_extension" "ama" {
  count = var.vm_count

  name                      = "AzureMonitorWindowsAgent-${count.index}"
  publisher                 = "Microsoft.Azure.Monitor"
  type                      = "AzureMonitorWindowsAgent"
  type_handler_version      = "1.22"
  virtual_machine_id        = azurerm_windows_virtual_machine.this[count.index].id
  automatic_upgrade_enabled = true

  depends_on = [module.dcr]
}

# This is the module that creates the data collection rule
module "dcr" {
  source                                           = "../../"
  enable_telemetry                                 = var.enable_telemetry
  monitor_data_collection_rule_resource_group_name = azurerm_resource_group.this.name
  monitor_data_collection_rule_kind                = "Windows"
  monitor_data_collection_rule_location            = azurerm_resource_group.this.location
  monitor_data_collection_rule_name                = "microsoft-avdi-eastus"
  monitor_data_collection_rule_data_flow = [
    {
      destinations = [azurerm_log_analytics_workspace.this.name]
      streams      = ["Microsoft-Perf", "Microsoft-Event"]
    }
  ]

  monitor_data_collection_rule_destinations = {
    log_analytics = {
      name                  = azurerm_log_analytics_workspace.this.name
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
    }
  }

  monitor_data_collection_rule_data_sources = {
    performance_counter = [
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
    ],
    windows_event_log = [
      {
        name           = "eventLogsDataSource"
        streams        = ["Microsoft-Event"]
        x_path_queries = ["Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "System!*", "Microsoft-FSLogix-Apps/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "Application!*[System[(Level=2 or Level=3)]]", "Microsoft-FSLogix-Apps/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]"]
      }
    ]
  }
}

# Creates an association between an Azure Monitor data collection rule and a virtual machine.
resource "azurerm_monitor_data_collection_rule_association" "example" {
  count = var.vm_count

  target_resource_id      = azurerm_windows_virtual_machine.this[count.index].id
  data_collection_rule_id = module.dcr.resource.id
  name                    = "${var.avd_vm_name}-association-${count.index}"
}
