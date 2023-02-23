module "aws_eks" {
  source = "../../modules/aws-eks"

  application_name = "ws-test"
  region           = "ap-south-1"
}
