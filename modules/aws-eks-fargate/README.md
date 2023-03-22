# AWS EKS Terraform Module

### Table of Contents

- [Prerequisites](#prerequisites)
- [Module structure](#module-structure)
- [Example](#example)
- [Providers](#providers)

## Variables

- `application_name` - (Required) Application name
- `region` - (Required) Region
- `aws_access_key_id` - (Required)(Sensitive) AWS Access Key ID
- `aws_access_secret_key` - (Required)(Sensitive) AWS Access Secret Key
- `enable_aws_load_balancer_controller_addon` - (Optional) Enable AWS load balancer controller addon (default `true`)

For sensitive variables, please use `terraform.tfvars` file. You can see in [example](#example)

## Outputs

- `cluster_name` - EKS cluster name
- `cluster_arn` - EKS cluster ARN
- `cluster_endpoint` - EKS cluster endpoint
- `cluster_region` - Region where EKS cluster is deployed
- `vpc_id` - EKS Cluster VPC ID

## Usage

```hcl
module "aws_eks" {
  source = "git@github.com:wednesday-solutions/multi-cloud-terraform-module/modules/aws-eks-fargate"

  application_name = "ws-test"
  region           = "asia-south-1"

  vpc_id             = "vpc-xxxxxxxxx"
  security_group_ids = ["sg-xxxxxxxxxx"]
  private_subnet_ids = ["subnet-xxxxxxxxxx"]
  public_subnet_ids  = ["subnet-xxxxxxxxxx"]
}
```

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
- `terraform-helm-provider` - hashicorp/helm v2.9

#### Resources

- `aws_iam_role` - Create IAM role for EKS cluster and Fargate profile
- `aws_iam_role_policy_attachment` - Attach policy to IAM role
- `aws_eks_cluster` - Create EKS cluster
- `aws_eks_addon` - Addons for cluster
- `aws_eks_fargate_profile` - Create Fargate profile
- `kubernetes_annotations` - Patch annotations of kubernetes objects

#### DataSources

- `aws_eks_cluster_auth` - Access EKS cluster auth token
- `aws_subnets` - Access subnets of VPC with tag filter
