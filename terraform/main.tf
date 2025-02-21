# resource "random_string" "random" {
#   length  = 8
#   lower   = true
#   numeric = false
#   special = false
#   upper   = false
# }

resource "random_pet" "random_name"{

}
# # Call the AWS Base module
module "aws_base" {
  source = "./modules/aws_base"
  aws_config = local.aws_config
}
# # Call the AWS VPC module
module "aws_network" {
  source = "./modules/aws_network"
  #vpc_subnets = local.vpc_subnets
  aws_config = local.aws_config
  aws_s3_bucket = module.aws_base.aws_s3_bucket

  depends_on = [ module.aws_base ]
}
# # #Call the AWS servers module
module "aws_servers" {
  source = "./modules/aws_servers"
  aws_config = local.aws_config
  aws_subnets = module.aws_network.aws_subnets
  aws_security_groups = module.aws_network.aws_security_groups

  depends_on = [ module.aws_network ]
}
# #Call the AWS paas module
module "aws_paas" {
  source = "./modules/aws_paas"
  aws_config = local.aws_config
  aws_subnets = module.aws_network.aws_subnets
  aws_security_groups = module.aws_network.aws_security_groups
  aws_vpcs = module.aws_network.aws_vpcs
}

# # Call the AWS container module
# module "aws_container" {
#   source = "./modules/aws_container"
#   aws_config = local.aws_config
#   aws_subnets = module.aws_network.aws_subnets
# }

# Call the Azure VNet module
# module "azure_base" {
#   source = "./modules/azure_base"
#   azure_config = local.azure_config
# }

# # # Call the Azure VNet module
# module "azure_network" {
#   source = "./modules/azure_network"
#   azure_config = local.azure_config
#   azurerm_resource_group_rg=module.azure_base.azurerm_resource_group_rg
#   azurerm_storage_account_vnet_storage = module.azure_base.azurerm_storage_account_vnet_storage

  
#   depends_on = [ module.azure_base ]
#   }

# # Call the Azure Server module
# module "azure_servers" {
#   source = "./modules/azure_servers"
#   azure_config = local.azure_config  
#   azurerm_resource_group_rg=module.azure_base.azurerm_resource_group_rg
#   azurerm_subnets = module.azure_network.azurerm_subnets
#   azurerm_db_subnets= module.azure_network.azurerm_db_subnets
#   azurerm_network_security_group = module.azure_network.azurerm_network_security_group
# }

# # Call the AWS PaaS module
# module "azure_paas" {
#   source = "./modules/azure_paas"
#   azure_config = local.azure_config
#   azurerm_db_subnets = module.azure_network.azurerm_db_subnets
# }

# # Call the AWS Containers module
# module "azure_container" {
#   source = "./modules/azure_container"
#   azure_config = local.azure_config
# }

# # # Call the AWS to AZURE VPN module.
# module "vpn" {
#   source = "./modules/vpn"
#   aws_config = local.aws_config
#   azure_config = local.azure_config
#   aws_vpcs = module.aws_network.aws_vpcs
#   aws_eip_ngw = module.aws_network.aws_eip_ngw
#   aws_subnets =  module.aws_network.aws_subnets
#   azurerm_subnets = module.azure_network.azurerm_subnets
#   aws_route_table_public_rt = module.aws_network.aws_route_table_public_rt

# depends_on = [ module.aws_base, module.aws_network, module.azure_base, module.azure_network ]
# }



