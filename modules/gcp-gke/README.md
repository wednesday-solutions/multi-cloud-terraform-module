# GCP GKE Terraform Module

### Table of Contents

- [Prerequisites](#prerequisites)
- [Module structure](#module-structure)
- [Example](#example)
- [Providers](#providers)

## Prerequisites

- Google Console Account with Project
- CLI tools
  - `terraform`
  - `gcloud`

## Module structure

- **Variables**

  - `project_id` - (Required)(Sensitive) Google Project ID
  - `region` - (Required) Region
  - `cluster_name` - (Required) Cluster name
  - `aws_access_secret_key` - (Required)
  - `cluster_addons` - (Optional) EKS cluster addons

  For sensitive variables, please use `terraform.tfvars` file. You can see in [example](#example)

- **Outputs**

  - `cluster_name` - EKS cluster name
  - `cluster_arn` - EKS cluster ARN
  - `cluster_endpoint` - EKS cluster endpoint
  - `cluster_region` - Region where EKS cluster is deployed

## Example

- Authenticate Google Cloud Platform

```bash
gcloud auth application-defeault login
```

- Go to directory

```bash
cd examples/gcp-gke
```

- Setup input variables

```bash
cp terraform.tfvars.sample terraform.tfvars
```

- Fill in Google project credentials in `terraform.tfvars` file

  - `project_id` = Google Project ID

- Install required terraform providers

```bash
terraform init
```

- Deploy infra

```bash
terraform apply
```

## Providers

- `terraform-google-provider` - hashicorp/aws v4

#### Resources

- `google_container_cluster` - Create GKE cluster
