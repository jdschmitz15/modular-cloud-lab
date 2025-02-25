resource "azurerm_mssql_managed_instance" "mssql_managed_instance" {
  for_each                     = var.azure_config.managedDBs
  name                         = format("%s-server", each.key)
  resource_group_name          = var.azure_config.resourceGroup
  location                     = var.azure_config.location
  administrator_login          = "mradministrator"
  administrator_login_password = "thisIsDog11"
  license_type                 = "BasePrice"
  subnet_id                    = var.azurerm_db_subnets["${each.value["vnet"]}.${each.value["subnet"]}"].id
  sku_name                     = "GP_Gen5"
  vcores                       = 4
  storage_size_in_gb           = 32
}

resource "azurerm_mssql_managed_database" "mssql_managed_database" {
  for_each            = var.azure_config.managedDBs
  managed_instance_id = azurerm_mssql_managed_instance.mssql_managed_instance[each.key].id
  name                = format("%s-db", each.key)
}