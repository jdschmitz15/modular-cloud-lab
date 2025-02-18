
variable "azure_config" {
  description = "Azure configuration settings"
  type = object({
    sshKey=string
    location = string
    centralLogging = bool
    blobFlowLogName = string
    blobFlowLogRG = string
    vnets = map(object({
      addressSpace = string
      subnets = map(object({
        addressSpace = string
        nsg = string
      }))
    }))
    vnetPairings = map(list(string))
    vpnConnections = map(object({
      awsVPC = string
      subnet = string
      azureNetwork = string
    }))
    networkSecurityGroups = map(object({
      logFlows = bool
      rules = map(object({
        destinationPortRange = string
        sourceAddressPrefixes = list(string)
        priority = number
      }))
    }))
    vnetFlowLogs = map(object({
      logFlows = bool
    }))
    windowsVMs = map(any)
    linuxVMs = map(object({
      vnet = string
      subnet = string
      nsg = string
      size = string
      publicIP = bool
      staticIP = string
      tags = map(string)
    }))
    managedDBs = map(any)
    aksClusters = map(object({
      nodeCount = number
      adminUserName = string
      cni = string
    }))
    resourceGroup = string
    admin_cidr_list = list(string)    
  })
}

variable "azurerm_network_security_group" {
  description = "Storage account for VNET flow logs"
  type = any
}

variable "azurerm_subnets" {
  description = "A map of security group ids"
  type = map(any)
}
variable "azurerm_db_subnets" {
  description = "A map of security group ids"
  type = map(any)
}

variable "azurerm_resource_group_rg" {
  description = "A map of security group ids"
  type = map(any)
}