terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azapi" {}

data "azapi_client_config" "this" {}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"

  suffix = ["avd-monitoring"]
}

resource "azapi_resource" "rg" {
  location  = var.location
  name      = module.naming.resource_group.name
  parent_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
  tags      = local.tags
}

resource "azapi_resource" "host_pool" {
  location  = var.location
  name      = "vdpool-entraid-001"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.DesktopVirtualization/hostPools@2024-04-03"
  body = {
    properties = {
      hostPoolType          = "Pooled"
      loadBalancerType      = "BreadthFirst"
      preferredAppGroupType = "Desktop"
    }
  }
  tags = local.tags
}

resource "azapi_resource" "user_assigned_identity" {
  location  = var.location
  name      = "uai-avd-dcr"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  tags      = local.tags
}

# The subnet is declared inline so that Terraform makes a single write to the
# virtual network, rather than racing separate subnet writes against each other.
resource "azapi_resource" "vnet" {
  location  = var.location
  name      = module.naming.virtual_network.name_unique
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
      }
      subnets = [
        {
          name = local.subnet_name
          properties = {
            addressPrefix = "10.0.1.0/24"
          }
        }
      ]
    }
  }
  tags = local.tags
}

resource "azapi_resource" "log_analytics_workspace" {
  location  = var.location
  name      = var.log_analytics_workspace_name
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
  tags = local.tags
}

resource "azapi_resource" "nic" {
  count = var.vm_count

  location  = var.location
  name      = "${var.avd_vm_name}-${count.index}-nic"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Network/networkInterfaces@2024-05-01"
  body = {
    properties = {
      ipConfigurations = [
        {
          name = "internal"
          properties = {
            privateIPAllocationMethod = "Dynamic"
            subnet = {
              id = "${azapi_resource.vnet.id}/subnets/${local.subnet_name}"
            }
          }
        }
      ]
    }
  }
  tags = local.tags
}

# Generate VM local password
resource "random_password" "vmpass" {
  length  = 20
  special = true
}

resource "azapi_resource" "vm" {
  count = var.vm_count

  location  = var.location
  name      = "${var.avd_vm_name}-${count.index}"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Compute/virtualMachines@2024-07-01"
  body = {
    # Spread the session hosts across availability zones, as required by the
    # Azure Proactive Resiliency Library.
    zones = [tostring((count.index % 3) + 1)]
    properties = {
      hardwareProfile = {
        vmSize = "Standard_D2s_v5"
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.nic[count.index].id
          }
        ]
      }
      osProfile = {
        adminUsername = "adminuser"
        computerName  = "${var.avd_vm_name}-${count.index}"
      }
      securityProfile = {
        encryptionAtHost = true
      }
      storageProfile = {
        imageReference = {
          offer     = "windows-11"
          publisher = "microsoftwindowsdesktop"
          sku       = "win11-23h2-avd"
          version   = "latest"
        }
        osDisk = {
          caching      = "ReadWrite"
          createOption = "FromImage"
          managedDisk = {
            storageAccountType = "Premium_LRS"
          }
          name = "${var.avd_vm_name}-${count.index}-osdisk"
        }
      }
    }
  }
  sensitive_body = {
    properties = {
      osProfile = {
        adminPassword = random_password.vmpass.result
      }
    }
  }
  tags = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azapi_resource.user_assigned_identity.id]
  }
}

# Virtual Machine Extension for the Azure Monitor Agent, which is what actually
# collects the data described by the Data Collection Rule.
resource "azapi_resource" "ama" {
  count = var.vm_count

  name      = "AzureMonitorWindowsAgent"
  parent_id = azapi_resource.vm[count.index].id
  type      = "Microsoft.Compute/virtualMachines/extensions@2024-07-01"
  body = {
    properties = {
      autoUpgradeMinorVersion = true
      enableAutomaticUpgrade  = true
      publisher               = "Microsoft.Azure.Monitor"
      type                    = "AzureMonitorWindowsAgent"
      typeHandlerVersion      = "1.22"
    }
  }
  location = var.location
  tags     = local.tags
}

# This is the module that creates the data collection rule
module "dcr" {
  source = "../../"

  data_flows = [
    {
      destinations = [var.log_analytics_workspace_name]
      streams      = ["Microsoft-Perf", "Microsoft-Event"]
    }
  ]
  location  = var.location
  name      = "microsoft-avdi-eastus"
  parent_id = azapi_resource.rg.id
  data_sources = {
    performance_counters = [
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
    ]
    windows_event_logs = [
      {
        name           = "eventLogsDataSource"
        streams        = ["Microsoft-Event"]
        x_path_queries = ["Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "System!*", "Microsoft-FSLogix-Apps/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]", "Application!*[System[(Level=2 or Level=3)]]", "Microsoft-FSLogix-Apps/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]"]
      }
    ]
  }
  destinations = {
    log_analytics = [
      {
        name                  = var.log_analytics_workspace_name
        workspace_resource_id = azapi_resource.log_analytics_workspace.id
      }
    ]
  }
  enable_telemetry = var.enable_telemetry
  kind             = "Windows"
  tags             = local.tags
}

# Creates an association between an Azure Monitor data collection rule and a virtual machine.
resource "azapi_resource" "dcr_association" {
  count = var.vm_count

  name      = "${var.avd_vm_name}-association-${count.index}"
  parent_id = azapi_resource.vm[count.index].id
  type      = "Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11"
  body = {
    properties = {
      dataCollectionRuleId = module.dcr.resource_id
    }
  }

  depends_on = [azapi_resource.ama]
}
