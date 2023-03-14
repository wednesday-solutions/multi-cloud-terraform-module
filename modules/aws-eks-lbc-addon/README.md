# AWS EKS Load Balancer Controller Add On

This modules create AWS load balancer controller addon for existing EKS cluster

> This module can only used as child module of `aws-eks` module, since it inherits providers from it

## Module structure

- **Variables**

  - `application_name` - (Required) Application name
  - `region` - (Required) Region
  - `cluster_oidc_issuer` - (Required) Cluster OIDC issuer URL
  - `cluster_name` - (Required) EKS cluster name
  - `vpc_id` - (Required) EKS Cluster VPC ID
  - `cluster_endpoint` - (Required) EKS cluster endpoint
  - `cluster_ca_certificate` - (Required) EKS cluster CA ceritificate
  - `cluster_token` - (Required) EKS cluster token

## Inherited providers

- `terraform-provider-aws`
- `terraform-provider-kubernetes`
- `terraform-provider-helm`

## Resources created

- `aws_iam_openid_connect_provider` - OpenID connect provider for cluster
- `aws_iam_role` - IAM role for load balancer controller
- `kubernetes_service_account` - Service Account for LBC
- `helm_release` - Install aws-load-balancer-controller chart
- `null_resource.target_group_binding_crds` - Installs target group binding CRDs
