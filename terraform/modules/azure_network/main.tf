resource "azurerm_virtual_network" "vnets" {
  for_each            = var.azure_config.vnets
  name                = each.key
  address_space       = [each.value["addressSpace"]]
  location            = var.azurerm_resource_group_rg[0].location
  resource_group_name = var.azurerm_resource_group_rg[0].name
}

resource "azurerm_subnet" "subnets" {
  for_each = {
    for subnet in local.vnet_subnets : "${subnet.vnet_name}.${subnet.subnet_key}" => subnet if subnet.subnet_key != "DBSubnet"
  }
  name                 = each.value["subnet_key"]
  resource_group_name  = var.azurerm_resource_group_rg[0].name
  virtual_network_name = each.value["vnet_name"]
  address_prefixes     = [each.value["address_space"]]
}

resource "azurerm_subnet" "db_subnets" {
  for_each = {
    for subnet in local.vnet_subnets : "${subnet.vnet_name}.${subnet.subnet_key}" => subnet if subnet.subnet_key == "DBSubnet"
  }
  name                 = each.value["subnet_key"]
  resource_group_name  = var.azurerm_resource_group_rg[0].name
  virtual_network_name = each.value["vnet_name"]
  address_prefixes     = [each.value["address_space"]]

  service_endpoints = ["Microsoft.Sql"] # Allow access to Azure SQL Database


  delegation {
    name = "dbServiceDelegation"
    service_delegation {
      name    = "Microsoft.Sql/managedInstances"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }

}

# Not updating NSG rules so we don't override other rules.
resource "azurerm_network_security_group" "nsg" {
  for_each            = var.azure_config.networkSecurityGroups
  name                = each.key
  location            = var.azure_config.location
  resource_group_name = var.azure_config.resourceGroup

  dynamic "security_rule" {
    for_each = each.value.rules
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destinationPortRange
      source_address_prefixes    = concat(security_rule.value.sourceAddressPrefixes, var.azure_config.admin_cidr_list)
      destination_address_prefix = "*"
    }
  }

  lifecycle {
    ignore_changes = [ security_rule ]
  }
}
resource "azurerm_network_watcher_flow_log" "nw_flog" {
  for_each             = { for k, v in var.azure_config.networkSecurityGroups : k => v if v.logFlows }
  network_watcher_name = "NetworkWatcher_eastus" # make this dynamic
  resource_group_name  = "NetworkWatcherRG"
  name                 = each.key

  target_resource_id   = azurerm_network_security_group.nsg[each.key].id
  #storage_account_id   = var.azure_config.centralLogging ? data.azurerm_storage_account.central_nsg_storage[0].id : var.azurerm_storage_account_vnet_storage[each.key].id
  storage_account_id   = var.azurerm_storage_account_vnet_storage[each.key].id
#  storage_account_id        = azurerm_storage_account.storage[each.key].id
  enabled              = true
  version              = 2

  retention_policy {
    enabled = true
    days    = 7
  }
}

resource "azurerm_virtual_network_peering" "vnets_peering-1" {
  for_each                     = var.azure_config.vnetPairings
  name                         = "${each.key}-1"
  resource_group_name          = var.azure_config.resourceGroup
  virtual_network_name         = each.value[1]
  remote_virtual_network_id    = azurerm_virtual_network.vnets[each.value[0]].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "vnets_peering-2" {
  for_each                     = var.azure_config.vnetPairings
  name                         = "${each.key}-2"
  resource_group_name          = var.azure_config.resourceGroup
  virtual_network_name         = each.value[0]
  remote_virtual_network_id    = azurerm_virtual_network.vnets[each.value[1]].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}


resource "azurerm_route_table" "azure_rt" {
  for_each = {
    for subnet in local.vnet_subnets : "${subnet.vnet_name}.${subnet.subnet_key}" => subnet if subnet.subnet_key == "DBSubnet"
  }
  name                =  each.key
  location = var.azure_config.location
  resource_group_name  = var.azurerm_resource_group_rg[0].name

  # route {
  #   name                   = "example"
  #   address_prefix         = "10.100.0.0/14"
  #   next_hop_type          = "VirtualAppliance"
  #   next_hop_in_ip_address = "10.10.1.1"
  # }
}

resource "azurerm_subnet_route_table_association" "azure_rta" {
  for_each = {
    for subnet in local.vnet_subnets : "${subnet.vnet_name}.${subnet.subnet_key}" => subnet if subnet.subnet_key == "DBSubnet"
  }
  subnet_id      = azurerm_subnet.db_subnets[each.key].id
  route_table_id = azurerm_route_table.azure_rt[each.key].id
}

# data "azurerm_storage_account" "central_nsg_storage" {
#   count               = var.azure_config.centralLogging ? 1: 0 
#   name                = var.azure_config.blobFlowLogName
#   resource_group_name = var.azure_config.blobFlowLogRG
# }

# resource "azurerm_network_watcher_flow_log" "vnet_flow_log" {
#   for_each             = { for k, v in var.azure_config.vnetFlowLogs : k => v if v.logFlows }
#   network_watcher_name = "NetworkWatcher_eastus" # make this dynamic
#   resource_group_name  = "NetworkWatcherRG"
#   name                 = each.key

#   target_resource_id   = azurerm_virtual_network.vnets[each.key].id
#   storage_account_id   = var.azurerm_storage_account_vnet_storage[each.key].id
#   enabled              = true
#   version              = 2

#   retention_policy {
#     enabled = true
#     days    = 7
#   }
# }


# # Public IP Address for the Application Gateway
# resource "azurerm_public_ip" "app_gw_pip" {
#   for_each = var.azure_config.appGateways
#   name                = each.key
#   location            = each.value["location"]
#   resource_group_name = var.azure_config.resourceGroup
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   zones               = ["1", "2", "3"]
# }


# # Application Gateway with Path-Based Routing
# resource "azurerm_application_gateway" "app_gw" {
#   for_each = var.azure_config.appGateways
#   name                = each.key
#   resource_group_name = var.azure_config.resourceGroup
#   location            = each.value["location"]
#   sku {
#     name     = "Standard_v2"
#     tier     = "Standard_v2"
#     capacity = 1
#   }
#   zones = ["1", "2", "3"]

#   gateway_ip_configuration {
#     name  = "${each.key}-gw-ip-config"
#     subnet_id = azurerm_subnet.subnets[each.value["subnet"]].id
#   }

#   frontend_ip_configuration {
#     name                 = "${each.key}-fontend-ip-config"
#     public_ip_address_id = azurerm_public_ip[each.key].id
#   }

#   frontend_port {
#     name = "${each.key}-frontendPort"
#     port = 80
#   }

#   backend_address_pool {
#     name = "backendPoolApi"
#   }

#   backend_address_pool {
#     name = "backendPoolImages"
#   }

#   backend_http_settings {
#     name                  = "httpSettingsApi"
#     cookie_based_affinity  = "Disabled"
#     port                  = 80
#     protocol              = "Http"
#     request_timeout       = 20
#   }

#   backend_http_settings {
#     name                  = "httpSettingsImages"
#     cookie_based_affinity  = "Disabled"
#     port                  = 80
#     protocol              = "Http"
#     request_timeout       = 20
#   }

#   http_listener {
#     name                           = "appGwHttpListener"
#     frontend_ip_configuration_name = "appGwFrontendIP"
#     frontend_port_name             = "frontendPort"
#     protocol                       = "Http"
#   }

#   # URL Path Map for Path-Based Routing
#   url_path_map {
#     name               = "pathMap"
#     default_backend_address_pool_name  = "backendPoolApi"
#     default_backend_http_settings_name = "httpSettingsApi"

#     path_rule {
#       name                       = "imagesRule"
#       paths                      = ["/images/*"]
#       backend_address_pool_name   = "backendPoolImages"
#       backend_http_settings_name  = "httpSettingsImages"
#     }
#   }

#   request_routing_rule {
#     name                       = "pathBasedRoutingRule"
#     rule_type                  = "PathBasedRouting"
#     http_listener_name         = "appGwHttpListener"
#     url_path_map_name          = "pathMap"
#   }

#   tags = {
#     marketplaceItemId = "Microsoft.ApplicationGateway"
#   }
# }


# resource "azurerm_network_interface_backend_address_pool_association" "app_gw_nic_pool" {
#     for_each = var.azure_config.appGateways
# }

