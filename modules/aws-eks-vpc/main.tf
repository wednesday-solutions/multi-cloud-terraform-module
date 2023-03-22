locals {
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    Private                           = true
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    Public                   = true
  }
}

# VPC

resource "aws_vpc" "default" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.application_name}/VPC"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "default" {
  tags = {
    Name = "${var.application_name}/InternetGateway"
  }
}

# VPC Gateway Attachment

resource "aws_internet_gateway_attachment" "vpc_default" {
  vpc_id              = aws_vpc.default.id
  internet_gateway_id = aws_internet_gateway.default.id
}

# Private subnets

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.default.id

  availability_zone       = var.private_subnets[count.index].availability_zone
  cidr_block              = var.private_subnets[count.index].cidr_block
  map_public_ip_on_launch = false

  tags = merge({
    "Name" = "${var.application_name}/PrivateSubnet${var.private_subnets[count.index].name}"
    },
    local.private_subnet_tags
  )
}

# Public subnets

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id = aws_vpc.default.id

  availability_zone       = var.public_subnets[count.index].availability_zone
  cidr_block              = var.public_subnets[count.index].cidr_block
  map_public_ip_on_launch = true

  tags = merge({
    "Name" = "${var.application_name}/PublicSubnet${var.public_subnets[count.index].name}"
    },
    local.public_subnet_tags
  )
}

# Private Networking

resource "aws_route_table" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${var.application_name}/PrivateRouteTable${var.private_subnets[count.index].name}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  route_table_id = aws_route_table.private[count.index].id
  subnet_id      = aws_subnet.private[count.index].id
}

# Public Networking

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.default.id
  tags = {
    Name = "${var.application_name}/PublicRouteTable"
  }
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
  route_table_id         = aws_route_table.public.id

  depends_on = [
    aws_internet_gateway_attachment.vpc_default
  ]
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

# NATIP

resource "aws_eip" "nat_ip" {
  vpc = true
  tags = {
    Name = "${var.application_name}/NATIP"
  }
  depends_on = [
    aws_internet_gateway_attachment.vpc_default
  ]
}

# NAT Gateway

resource "aws_nat_gateway" "default" {
  allocation_id = aws_eip.nat_ip.allocation_id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.application_name}/NATGateway"
  }
}

# NAT Private Route

resource "aws_route" "nat_private" {
  count = length(aws_route_table.private)

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default.id
  route_table_id         = aws_route_table.private[count.index].id
}

# Security Groups

resource "aws_security_group" "control_plane_sg" {
  vpc_id      = aws_vpc.default.id
  description = "Communication between the control plane and worker nodegroups"
  tags = {
    Name = "${var.application_name}/ControlPlaneSecurityGroup"
  }

  depends_on = [
    aws_route.nat_private,
    aws_route.public,
    aws_route_table_association.public,
    aws_route_table_association.private,
  ]
}
