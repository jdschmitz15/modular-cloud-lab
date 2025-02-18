  locals {
    vpc_subnets = flatten([
    for vpc_name, vpc in var.aws_config.vpcs : [
      for subnet_key, subnet in vpc.subnets : {
        vpc_name    = vpc_name
        subnet_key  = subnet_key
        subnet_name = "${vpc_name}.${subnet_key}"
        #vpc_id      = module.aws_network.aws_vpc.vpcs[vpc_name].id
        cidr_block  = subnet["cidrBlock"]
        public      = subnet["public"]
        az          = "${var.aws_config.region}${subnet["az"]}"
      }
    ]
  ])
  }