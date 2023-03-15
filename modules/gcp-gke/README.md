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
  - `application_name` - (Required) Application name

  For sensitive variables, please use `terraform.tfvars` file. You can see in [example](#example)

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
