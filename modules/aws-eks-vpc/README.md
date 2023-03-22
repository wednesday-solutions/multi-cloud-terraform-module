# AWS EKS VPC module

> Spin up EKS compliant VPC

## Input variables

- `application_name` - Application name
- `vpc_cidr_block` - CIDR block for VPC
- `public_subnets` - Configuration for public subnets
- `private_subnets` - Configuration for private subnets

- `public_subnets/private_subnets`
  - `name` - Name of subnet
  - `availability_zone` - Availability zone of subnet
  - `cidr_block` - CIDR block for subnet

## Outputs

- `vpc_id` - VPC ID
- `private_subnet_ids` - Private subnet IDs
- `public_subnet_ids` - Public subnet IDs
- `security_group_id` - Security Group ID

## Usage

```hcl
provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_access_secret_key
  region     = local.region
}

module "aws_eks_vpc" {
  source = "git@github.com:wednesday-solutions/multi-cloud-terraform-module/modules/aws-eks-vpc"

  application_name = "ws-test-vpc"

  vpc_cidr_block = "192.168.0.0/16"

  public_subnets = [
    {
      name              = "APSOUTHEAST1A"
      availability_zone = "ap-southeast-1a"
      cidr_block        = "192.168.0.0/19"
    },
    {
      name              = "APSOUTHEAST1B"
      availability_zone = "ap-southeast-1b"
      cidr_block        = "192.168.32.0/19"
    },
    {
      name              = "APSOUTHEAST1C"
      availability_zone = "ap-southeast-1c"
      cidr_block        = "192.168.64.0/19"
    }
  ]

  private_subnets = [
    {
      name              = "APSOUTHEAST1A"
      availability_zone = "ap-southeast-1a"
      cidr_block        = "192.168.96.0/19"
    },
    {
      name              = "APSOUTHEAST1B"
      availability_zone = "ap-southeast-1b"
      cidr_block        = "192.168.128.0/19"
    },
    {
      name              = "APSOUTHEAST1C"
      availability_zone = "ap-southeast-1c"
      cidr_block        = "192.168.160.0/19"
    }
  ]
}
```

## Resources created

- `aws_vpc` - VPC
- `aws_internet_gateway` - Internet gateway
- `aws_internet_gateway_attachment` - Internet gateway attachment
- `aws_subnet` - Subnet
- `aws_route` - Route
- `aws_route_table` - Route table
- `aws_route_table_association` - Route table association
- `aws_eip` - Elastic IP address
- `aws_nat_gateway` - NAT gateway
- `aws_security_group`- Security Group
