output "aws_vpcs" {
  value = { for k, v in aws_vpc.vpcs : k => v }
}


# output "aws_subnets_id_map" {
#   value = { for k, v in aws_subnet.subnets : k => v.id }
# }

# output "vpc_subnets" {
#   value = local.vpc_subnets
# }

output "aws_subnets" {
  value = { for k, v in aws_subnet.subnets : k => v }
}

output "aws_security_groups" {
  value = { for k, v in aws_security_group.base : k => v  }
}

output "aws_route_table_public_rt" {
  value = { for k, v in aws_route_table.public : k => v }
}

output "aws_eip_ngw" {
  value = { for k, v in aws_eip.ngw_eips : k => v }
}