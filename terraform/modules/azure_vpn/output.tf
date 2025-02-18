output "azure_public_ip_vpns" {
  value = {for k, v in azurerm_public_ip.vgw_pip  : k => azurerm_public_ip.vgw_pip}
}