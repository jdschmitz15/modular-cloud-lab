// Create 1 VPC for every entry in the config file
resource "aws_vpc" "vpcs" {
  for_each             = var.aws_config.vpcs
  cidr_block           = each.value["cidrBlock"]
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = each.key
  }
}

// Create subnets based on VPC configs
resource "aws_subnet" "subnets" {
  for_each = {
    for subnet in local.vpc_subnets : "${subnet.vpc_name}.${subnet.subnet_key}" => subnet
  }
  vpc_id                  = each.value.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.public
  tags = {
    Name = each.key
  }
}

// Create the SSH key pair
resource "aws_key_pair" "auth" {
  for_each   = var.aws_config.vpcs
  key_name   = each.key
  public_key = file("${var.aws_config.sshKey}.pub")
}

# // Create 1 s3 bucket for VPC flow logs
# resource "aws_s3_bucket" "flow_logs" {
#   bucket        = "terraformvpcflowlogs"
#   force_destroy = true
# }

// Enable VPC flow logging for all VPCs
resource "aws_flow_log" "vpc_flow_log" {
  for_each = { for k, v in var.aws_config.vpcs : k => v if v.logFlows }
  log_destination      = var.aws_s3_bucket
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpcs[each.key].id
}

resource "aws_route_table" "private" {
  for_each = var.aws_config.vpcs
  vpc_id   = aws_vpc.vpcs[each.key].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngws[each.key].id
  }

  route {
    cidr_block         = "192.168.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  
  tags = {
    Name = "${each.key}-private-rt"
  }
}

resource "aws_route_table" "public" {
  for_each = var.aws_config.vpcs
  vpc_id   = aws_vpc.vpcs[each.key].id
  tags = {
    Name = "${each.key}-public-rt"
  }
}

# resource "aws_route" "vgw" {
#   for_each = local.azure_config.vpnConnections
#   route_table_id            = aws_route_table.public[each.value["awsVPC"]].id
#   destination_cidr_block    = each.value["azureNetwork"]
#   gateway_id                = aws_vpn_gateway.azurevpn[each.key].id
# }

resource "aws_route" "igw" {
  for_each = var.aws_config.vpcs
  route_table_id            = aws_route_table.public[each.key].id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igws[each.key].id
}

resource "aws_route" "tgw" {
  for_each = var.aws_config.vpcs
  route_table_id            = aws_route_table.public[each.key].id
  destination_cidr_block    = "192.168.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  depends_on = [aws_ec2_transit_gateway.tgw, aws_ec2_transit_gateway_vpc_attachment.tgw-attachment]
}

resource "aws_route_table_association" "public_rta" {
  for_each = {
    for subnet in local.vpc_subnets : "${subnet.vpc_name}.${subnet.subnet_key}" => subnet if subnet.public
  }
  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.public[each.value["vpc_name"]].id
}

resource "aws_route_table_association" "private_rta" {
  for_each = {
    for subnet in local.vpc_subnets : "${subnet.vpc_name}.${subnet.subnet_key}" => subnet if subnet.public == false
  }
  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.private[each.value["vpc_name"]].id
}

resource "aws_ec2_managed_prefix_list" "rfc1918" {
  name           = "rfc1918"
  address_family = "IPv4"
  max_entries    = 3

  entry {
    cidr = "10.0.0.0/8"
  }
  entry {
    cidr = "172.16.0.0/12"
  }
  entry {
    cidr = "192.168.0.0/16"
  }
}

resource "aws_ec2_managed_prefix_list" "admin" {
  name           = "admin"
  address_family = "IPv4"
  max_entries    = length(var.aws_config.admin_cidr_list)

  dynamic "entry" {
    for_each = var.aws_config.admin_cidr_list

    content {
      cidr = entry.value
    }
  }
}

resource "aws_security_group" "base" {
  for_each    = var.aws_config.vpcs
  name        = "${each.key}-base"
  description = "default rules for lab workloads"
  vpc_id      = aws_vpc.vpcs[each.key].id

  dynamic "ingress" {
    for_each = var.aws_config.allowedPorts.private
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      prefix_list_ids = [aws_ec2_managed_prefix_list.rfc1918.id, aws_ec2_managed_prefix_list.admin.id]
    }
  }

  dynamic "ingress" {
    for_each = var.aws_config.allowedPorts.public
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  // Allow outbound all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Each VPC gets an internet gateway
resource "aws_internet_gateway" "igws" {
  for_each = var.aws_config.vpcs
  vpc_id   = aws_vpc.vpcs[each.key].id
  tags = {
    Name = "${each.key}.igw"
  }
}


// Each VPC gets an elastic IP for the nat gateway
resource "aws_eip" "ngw_eips" {
  for_each = var.aws_config.vpcs
  domain   = "vpc"
  tags = {
    Name = "${each.key}-ngw-eip"
  }
}

// Every public subnet gets a nat gateway - logic assumes only 1 public subnet per VPC
resource "aws_nat_gateway" "ngws" {
  for_each = {
    for subnet in local.vpc_subnets : subnet.vpc_name => subnet if subnet.public
  }
  connectivity_type = "public"
  allocation_id     = aws_eip.ngw_eips[each.value["vpc_name"]].id
  subnet_id         = aws_subnet.subnets[each.value["subnet_name"]].id
  depends_on        = [aws_internet_gateway.igws]
  tags = {
    Name = "${each.value["subnet_name"]}-ngw"
  }
}

// Create 1 transit gateways to connect all the VPCs
resource "aws_ec2_transit_gateway" "tgw" {
  description                    = "transit gateway to connect vpcs"
  dns_support                    = "enable"
  vpn_ecmp_support               = "enable"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = replace(replace("config-files/${terraform.workspace}-aws.yaml-tgw", "-",""),"_","")
  }
}

// Attach the transit gateway to all subnets in the VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-attachment" {
  for_each           = var.aws_config.vpcs
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpcs[each.key].id
  subnet_ids         = [for subnetName, v in var.aws_config.vpcs[each.key].subnets : aws_subnet.subnets["${each.key}.${subnetName}"].id]
}
