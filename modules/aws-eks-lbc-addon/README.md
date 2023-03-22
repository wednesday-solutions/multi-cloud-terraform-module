# AWS EKS Load Balancer Controller Add On

This modules deploys AWS load balancer controller addon into an existing EKS cluster

## Variables

- `application_name` - (Required) Application name
- `region` - (Required) Region
- `cluster_name` - (Required) EKS cluster name

## Usage

```hcl
module "aws_eks_lbc" {
  source = "git@github.com:wednesday-solutions/multi-cloud-terraform-module/modules/aws-eks-lbc-addon"

  application_name = "ws-test"
  region           = "ap-south-1"

  cluster_name = "ws-test-cluster"
}
```

## Providers

- `terraform-provider-aws`
- `terraform-provider-kubernetes`
- `terraform-provider-helm`

## Resources created

- `aws_iam_openid_connect_provider` - OpenID connect provider for cluster
- `aws_iam_role` - IAM role for load balancer controller
- `kubernetes_service_account` - Service Account for LBC
- `helm_release` - Install aws-load-balancer-controller chart
- `null_resource.target_group_binding_crds` - Installs target group binding CRDs
