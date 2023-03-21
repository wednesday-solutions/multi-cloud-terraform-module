locals {
  region           = "ap-southeast-1"
  application_name = "ws-test"
}

provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_access_secret_key
  region     = local.region
}

module "aws_eks_vpc" {
  source = "../../modules/aws-eks-vpc"

  application_name = local.application_name

  vpc_cidr_block = "192.168.0.0/16"

  public_subnets = [
    {
      name              = "APSOUTHEAST1A"
      availability_zone = "ap-southeast-1a"
      cidr_block        = "192.168.0.0/19"
    },
    {
      name              = "APSOUTHEAST1B"
      availability_zone = "ap-southeast-1b"
      cidr_block        = "192.168.32.0/19"
    },
    {
      name              = "APSOUTHEAST1C"
      availability_zone = "ap-southeast-1c"
      cidr_block        = "192.168.64.0/19"
    }
  ]

  private_subnets = [
    {
      name              = "APSOUTHEAST1A"
      availability_zone = "ap-southeast-1a"
      cidr_block        = "192.168.96.0/19"
    },
    {
      name              = "APSOUTHEAST1B"
      availability_zone = "ap-southeast-1b"
      cidr_block        = "192.168.128.0/19"
    },
    {
      name              = "APSOUTHEAST1C"
      availability_zone = "ap-southeast-1c"
      cidr_block        = "192.168.160.0/19"
    }
  ]
}

module "aws_eks" {
  source = "../../modules/aws-eks-fargate"

  application_name = local.application_name
  region           = local.region

  vpc_id             = module.aws_eks_vpc.vpc_id
  security_group_ids = [module.aws_eks_vpc.security_group_id]
  private_subnet_ids = module.aws_eks_vpc.private_subnet_ids
  public_subnet_ids  = module.aws_eks_vpc.public_subnet_ids
}
