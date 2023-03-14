locals {
  region = "ap-south-1"
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
}
