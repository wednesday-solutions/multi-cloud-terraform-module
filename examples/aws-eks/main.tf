
module "aws_eks" {
  source = "../../modules/aws-eks"

  aws_access_key_id     = var.aws_access_key_id
  aws_access_secret_key = var.aws_access_secret_key

  application_name = "ws-test"
  region           = "ap-south-1"
}
