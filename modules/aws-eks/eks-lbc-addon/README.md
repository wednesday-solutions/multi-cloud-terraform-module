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
