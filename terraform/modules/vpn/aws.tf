

resource "aws_customer_gateway" "azurevpn" {
  for_each = var.azure_config.vpnConnections
  bgp_asn    = 65000
  ip_address = azurerm_public_ip.vgw_pip[each.key].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "azure-vpn-cgw"
  }
}

resource "aws_vpn_gateway" "azurevpn" {
  for_each = var.azure_config.vpnConnections
  vpc_id = var.aws_vpcs[each.value["awsVPC"]].id
  tags = {
    Name = "azure-vpn-gw"
  }
}

resource "aws_vpn_connection" "azurevpn" {
  for_each = var.azure_config.vpnConnections
  customer_gateway_id = aws_customer_gateway.azurevpn[each.key].id
  vpn_gateway_id = aws_vpn_gateway.azurevpn[each.key].id
  type = aws_customer_gateway.azurevpn[each.key].type
  static_routes_only = true
  
}

resource "aws_vpn_connection_route" "azurevpn" {
  for_each = var.azure_config.vpnConnections
  destination_cidr_block = each.value["azureNetwork"]
  vpn_connection_id      = aws_vpn_connection.azurevpn[each.key].id
}

resource "aws_vpn_gateway_route_propagation" "aws_routes" {
  for_each = var.azure_config.vpnConnections
  vpn_gateway_id = aws_vpn_gateway.azurevpn[each.key].id
  route_table_id = var.aws_route_table_public_rt[each.value["awsVPC"]].id
}

