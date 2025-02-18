
resource "azurerm_resource_group" "rg" {
  count    = var.azure_config.resourceGroup == "" ? 0 : 1
  name     = var.azure_config.resourceGroup
  location = var.azure_config.location
}

resource "azurerm_storage_account" "vnet_storage" {
  for_each            = { for k, v in var.azure_config.vnetFlowLogs : k => v if v.logFlows && !var.azure_config.centralLogging }
  name                = replace(replace("${var.azure_config.resourceGroup}-${each.key}", "-", ""), "_", "")
  resource_group_name = var.azure_config.resourceGroup
  location            = var.azure_config.location

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"

  depends_on = [ azurerm_resource_group.rg ]
}



# resource "azurerm_storage_account" "nsg_storage" {
#   for_each            = { for k, v in var.azure_config.networkSecurityGroups : k => v if v.logFlows && !var.azure_config.centralLogging }
#   name                = replace(replace("${var.azure_config.resourceGroup}-${each.key}", "-", ""), "_", "")
#   resource_group_name = var.azure_config.resourceGroup
#   location            = var.azure_config.location

#   account_tier              = "Standard"
#   account_kind              = "StorageV2"
#   account_replication_type  = "LRS"
# }

