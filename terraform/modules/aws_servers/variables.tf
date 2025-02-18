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
      admin_cidr_list = list(string)
  })
}

variable "aws_security_groups" { 
  description = "A map of security group ids"
  type = map(any)
}

variable "aws_subnets" {
  description = "A map of security group ids"
  type = map(any)
}