resource "azurerm_kubernetes_cluster" "aks" {
  for_each            = var.azure_config.aksClusters
  resource_group_name = var.azure_config.resourceGroup
  location            = var.azure_config.location
  name                = each.key
  dns_prefix          = each.key
  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    temporary_name_for_rotation = "tmpnodepool"
    vm_size    = "Standard_A2_v2"
    node_count = each.value["nodeCount"]
    upgrade_settings {
      max_surge = "10%"
    }
  }
  linux_profile {
    admin_username = each.value["adminUserName"]

    ssh_key {
      key_data = file("${var.azure_config.sshKey}.pub")
    }
  }
  network_profile {
    network_plugin    = each.value["cni"]
    load_balancer_sku = "standard"
  }
}
