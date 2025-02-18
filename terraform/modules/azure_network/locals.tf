locals { 
  # flatten ensures that this local value is a flat list of objects, rather
  # than a list of lists of objects.
  vnet_subnets = flatten([
    for vnet_name, vnet in var.azure_config.vnets : [
      for subnet_key, subnet in vnet.subnets : {
        vnet_name     = vnet_name
        subnet_key    = subnet_key
        subnet_name   = "${vnet_name}.${subnet_key}"
        vnet_id       = azurerm_virtual_network.vnets[vnet_name].id
        address_space = subnet["addressSpace"]
        nsg = subnet["nsg"]
      }
    ]
  ])
}