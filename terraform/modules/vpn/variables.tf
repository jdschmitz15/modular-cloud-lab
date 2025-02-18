variable "aws_config" {
  description = "AWS configuration settings"
  type = object({
    region              = string
    dnsZone             = string
    dnsSuffix           = string
    sshKey              = string
    #s3FlowLogArn        = string
    route53AWSProfile   = string
    vpcs                = map(object({
      logFlows  = bool
      cidrBlock = string
      subnets   = map(object({
        cidrBlock = string
        az        = string
        public    = bool
      }))
      dbGroup = bool
    }))
    amis = map(object({
      ami   = string
      owner = string
      user  = string
    }))
    loadBalancers = map(object({
      vpc       = string
      hosts     = list(string)
      lbPort    = number
      targetPort = number
    }))
    ec2Instances = map(object({
      vpc       = string
      subnet    = string
      ami       = string
      type      = string
      volSizeGb = number
      publicIP  = bool
      staticIP  = string
      tags      = map(string)
    }))
    eksClusters = map(object({
      vpc                  = string
      subnets              = list(string)
      clusterNodeGroupSize = number
    }))
    rdsInstances = map(object({
      engine         = string
      engineVersion  = string
      instanceClass  = string
      vpc            = string
    }))
    lambdaFunctions = map(object({
      fileName       = string
      vpc            = string
      securityGroup  = string
      subnet         = string
    }))
    allowedPorts = object({
      private = list(number)
      public  = list(number)
    })
  })
}

variable "azure_config" {
  description = "Azure configuration settings"
  type = object({
    sshKey=string
    location = string
    centralLogging = bool
    blobFlowLogName = string
    blobFlowLogRG = string
    vnets = map(object({
      addressSpace = string
      subnets = map(object({
        addressSpace = string
        nsg = string
      }))
    }))
    vnetPairings = map(list(string))
    vpnConnections = map(object({
      awsVPC = string
      subnet = string
      azureNetwork = string
    }))
    networkSecurityGroups = map(object({
      logFlows = bool
      rules = map(object({
        destinationPortRange = string
        sourceAddressPrefixes = list(string)
        priority = number
      }))
    }))
    vnetFlowLogs = map(object({
      logFlows = bool
    }))
    windowsVMs = map(any)
    linuxVMs = map(object({
      vnet = string
      subnet = string
      nsg = string
      size = string
      publicIP = bool
      staticIP = string
      tags = map(string)
    }))
    managedDBs = map(any)
    aksClusters = map(object({
      nodeCount = number
      adminUserName = string
      cni = string
    }))
    resourceGroup = string
    admin_cidr_list = list(string)
  })
}

variable "aws_subnets" {
  description = "A map of security group ids"
  type = map(any)
}

variable "aws_vpcs" {
  type = map(any)
  
}
# variable "vpc_subnets" {
#   description = "A map of security group ids"
#   type = map(any)
# }


variable "aws_route_table_public_rt" {
  description = "A map of security group ids"
  type = map(any)
  
}
variable "azurerm_subnets" {
  description = "A map of security group ids"
  type = map(any)
}

variable "aws_eip_ngw" {
  description = "nat gateway ip"
  type = map(any)
}

