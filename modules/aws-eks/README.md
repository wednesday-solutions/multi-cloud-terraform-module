# AWS EKS Terraform Module

### Table of Contents

- [Prerequisites](#prerequisites)
- [Module structure](#module-structure)
- [Example](#example)
- [Providers](#providers)

## Prerequisites

- AWS account
- CLI tools
  - `terraform`

## Module structure

- **Variables**

  - `application_name` - Application name
  - `region` - Region
  - `aws_access_key_id` = AWS Access Key ID\*
  - `aws_access_secret_key` = AWS Access Secret Key\*

  `*` Sensitive variables. Please use `terraform.tfvars` file, you can see in [example](#example)

- **Outputs**

  - `cluster_name` - EKS cluster name
  - `cluster_arn` - EKS cluster ARN
  - `cluster_region` - Region where EKS cluster is deployed

## Example

- Go to directory

```bash
cd examples/aws-eks
```

- Setup input variables

```bash
cp terraform.tfvars.sample terraform.tfvars
```

- Fill in AWS credentials in `terraform.tfvars` file

  - `aws_access_key_id` = AWS Access Key ID
  - `aws_access_secret_key` = AWS Access Secret Key

- Install required terraform providers

```bash
terraform init
```

- Deploy infra

```bash
terraform apply
```

## Providers

- `terraform-aws-provider` - hashicorp/aws v4
- `terraform-kubernetes-provider` - hashicorp/kubernetes v2

#### Resources

- `aws_cloudformation` - Create EKS compliant VPC and Subnets
- `aws_iam_role` - Create IAM role for EKS cluster and Fargate profile
- `aws_iam_role_policy_attachment` - Attach policy to IAM role
- `aws_eks_cluster` - Create EKS cluster
- `aws_eks_addon` - Addons for cluster
- `aws_eks_fargate_profile` - Create Fargate profile
- `kubernetes_annotations` - Patch annotations of kubernetes objects

#### DataSources

- `aws_eks_cluster_auth` - Access EKS cluster auth token
- `aws_subnets` - Access subnets of VPC with tag filter
