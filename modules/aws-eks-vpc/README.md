# AWS EKS VPC module

## Input variables

- application_name
- vpc_cidr_block
- public_subnets
- private_subnets

- public_subnets/private_subnets
  - name
  - availability_zone
  - cidr_block

## Resources created

- aws_vpc
- aws_internet_gateway
- aws_internet_gateway_attachment
- aws_subnet
- aws_route
- aws_route_table
- aws_route_table_association
- aws_eip
- aws_nat_gateway
- aws_security_group
