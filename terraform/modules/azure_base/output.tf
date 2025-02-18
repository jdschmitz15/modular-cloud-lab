#Storage account 
output "azurerm_storage_account_vnet_storage" {
  value = {for k,v in azurerm_storage_account.vnet_storage : k => v}
 }

 output "azurerm_resource_group_rg" {
  value = {for k, v in azurerm_resource_group.rg : k => v}
 }