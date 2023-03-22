# Terraform Multi-Cloud Module

> Terraform module for multi-cloud infrastructure (EKS/GKE)

The goal here is to provision multi-cloud infrastructure using Kubernetes services from different cloud providers (AWS, GCP) that could bring forth several advantages including high availability, optimal performance and increased flexibility.

## Prequisites

- AWS Account
- GCP Project
- CLI tools
  - terraform
  - kubectl
  - aws
  - gcloud

## Modules

- [`aws-eks-vpc`](./modules/aws-eks-vpc/) - EKS compliant VPC
- [`aws-eks-fargate`](./modules/aws-eks-fargate/) - EKS cluster with Fargate profile
- [`aws-eks-lbc-addon`](./modules/aws-eks-lbc-addon/) - AWS load balancer controller add-on
- [`aws-ec2-nginx`](./modules/aws-ec2-nginx/) - NGINX server in EC2 instance
- [`gcp-gke-autopilot`](./modules/gcp-gke-autopilot/) - GKE cluster in autopilot mode

## Example

1. Create EKS cluster with Fargate profile and AWS load balancer controller

```bash

# 1. Go to directory
cd examples/aws-eks-fargate

# 2. Create terraform variables file.
cp terraform.tfvars.sample terraform.tfvars

# 3. Enter AWS credentials in terraform.tfvars
aws_access_key_id     = "<ACCESS_KEY>"
aws_access_secret_key = "<ACCESS_SECRET>"

# 3. Initialize terraform
terraform init

# 4. Apply infrastructure
terraform apply
```

2. Create GKE cluster in autopilot mode

```bash

# 1. Go to directory
cd examples/gcp-gke-autopilot

# 2. Create terraform variables file.
cp terraform.tfvars.sample terraform.tfvars

# 3. Enter GCP project ID in terraform.tfvars
project_id            = "<PROJECT_ID>"

# 3. Initialize terraform
terraform init

# 4. Apply infrastructure
terraform apply
```

3. Deploy sample application to both EKS and GCP cluster. This will also setup load balancers in respective cloud cluster

```bash

# 1. Go to directory
cd examples/multi-cloud-sample-app

# 2. Create terraform variables file.
cp terraform.tfvars.sample terraform.tfvars

# 3. Enter AWS & GCP credentials in terraform.tfvars
aws_access_key_id     = "<ACCESS_KEY>"
aws_access_secret_key = "<ACCESS_SECRET>"
project_id            = "<PROJECT_ID>"

# 3. Initialize terraform
terraform init

# 4. Apply infrastructure
terraform apply
```

4. Provision NGINX load balancer in EC2 instance which distributes the traffic to EKS & GKE load balancer

```bash

# 1. Go to directory
cd examples/multi-cloud-nginx-lb

# 2. Create terraform variables file.
cp terraform.tfvars.sample terraform.tfvars

# 3. Enter AWS & GCP credentials in terraform.tfvars
aws_access_key_id     = "<ACCESS_KEY>"
aws_access_secret_key = "<ACCESS_SECRET>"
project_id            = "<PROJECT_ID>"

# 3. Initialize terraform
terraform init

# 4. Apply infrastructure
terraform apply

```

## Roadmap

- [x] AWS EKS Cluster
- [x] GKE cluster autopilot mode
- [ ] EKS multi-region cluster using Global Accelerator
- [ ] GKE multi-region cluster using MCS (Multi Cluster Service)
- [ ] Multi-cloud load balancing with failover
