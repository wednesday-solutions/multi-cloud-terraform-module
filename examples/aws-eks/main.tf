locals {
  region = "ap-southeast-1"
}

provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_access_secret_key
  region     = local.region
}

module "aws_eks" {
  source = "../../modules/aws-eks"

  application_name = "ws-test"
  region           = local.region

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
