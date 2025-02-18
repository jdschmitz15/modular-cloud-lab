locals {
    # flatten ensures that this local value is a flat list of objects, rather
  # than a list of lists of objects.
  vpc_subnets = flatten([
    for vpc_name, vpc in var.aws_config.vpcs : [
      for subnet_key, subnet in vpc.subnets : {
        vpc_name    = vpc_name
        subnet_key  = subnet_key
        subnet_name = "${vpc_name}.${subnet_key}"
        vpc_id      =   aws_vpc.vpcs[vpc_name].id
        cidr_block  = subnet["cidrBlock"]
        public      = subnet["public"]
        az          = "${var.aws_config.region}${subnet["az"]}"
      }
    ]
  ])
}

