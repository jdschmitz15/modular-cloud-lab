# output "azure_vm_private_ip" {
#   value = { for k, v in azurerm_network_interface.vminterfaces : k => v.private_ip_address }
# }
# output "azure_vm_public_ip" {
#   value = { for k, v in azurerm_public_ip.public_ip : k => v.ip_address }
# }
# output "azure_private_dns" {
#   value = { for k, v in aws_route53_record.azure_vm_private_dns : k => "${v.name}.${data.aws_route53_zone.zone.name}" }
# }
# output "azure_public_dns" {
#   value = { for k, v in aws_route53_record.azure_vm_public_dns : k => "${v.name}.${data.aws_route53_zone.zone.name}" }
# }
# output "azure_aks_clusters" {
#   value = { for k, v in azurerm_kubernetes_cluster.aks : k => v.name }
# }
output "azurerm_subnets" {
  value = { for k, v in azurerm_subnet.subnets : k => v }
}

output "azurerm_db_subnets" {
  value = { for k, v in azurerm_subnet.db_subnets : k => v }
}

output "azurerm_virtual_network_vnets" {
  value = {for k,v in azurerm_virtual_network.vnets: k => v }
}
output "azurerm_network_security_group" {
  value = {for k,v in azurerm_network_security_group.nsg: k=>v}
}