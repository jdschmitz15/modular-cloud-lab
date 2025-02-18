output "azurerm_network_interfaces" {
    value = {for k, v in azurerm_network_interface.vminterfaces : k => v }
}