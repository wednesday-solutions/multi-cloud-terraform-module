locals {
  cluster_addons = { "vpc-cni" = "5m", "kube-proxy" = "5m", "coredns" = "30m" }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    Private                           = true
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    Public                   = true
  }
}

resource "aws_vpc" "default" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.application_name}/VPC"
  }
}

resource "aws_internet_gateway" "default" {
  tags = {
    Name = "${var.application_name}/InternetGateway"
  }
}

resource "aws_internet_gateway_attachment" "vpc_default" {
  vpc_id              = aws_vpc.default.id
  internet_gateway_id = aws_internet_gateway.default.id
}

# Private subnet

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.default.id

  availability_zone       = var.private_subnets[count.index].availability_zone
  cidr_block              = var.private_subnets[count.index].cidr_block
  map_public_ip_on_launch = false

  tags = merge({
    "Name" = "${var.application_name}/Subnet${var.private_subnets[count.index].name}"
    },
    local.private_subnet_tags
  )
}

# Public subnet

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id = aws_vpc.default.id

  availability_zone       = var.public_subnets[count.index].availability_zone
  cidr_block              = var.public_subnets[count.index].cidr_block
  map_public_ip_on_launch = true

  tags = merge({
    "Name" = "${var.application_name}/Subnet${var.public_subnets[count.index].name}"
    },
    local.public_subnet_tags
  )
}

# Private Network

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

# Public Network

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

# NAT

resource "aws_eip" "nat_ip" {
  vpc = true
  tags = {
    Name = "${var.application_name}/NATIP"
  }
  depends_on = [
    aws_internet_gateway_attachment.vpc_default
  ]
}

resource "aws_nat_gateway" "default" {
  allocation_id = aws_eip.nat_ip.allocation_id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.application_name}/NATGateway"
  }
}

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
}

# EKS Cluster IAM Role

resource "aws_iam_role" "cluster_role" {
  name = "${var.application_name}-AmazonEKSClusterRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

# EKS Cluster

resource "aws_eks_cluster" "cluster" {
  name     = "${var.application_name}-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.control_plane_sg.id]
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
  }

  tags = {
    Name = "${var.application_name}/ControlPlane"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_role_policy
  ]
}

# Fargate Pod Execution Role

resource "aws_iam_role" "fargate_role" {
  name = "${var.application_name}-AmazonEKSPodExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "${replace(aws_eks_cluster.cluster.arn, ":cluster/", ":fargateprofile/")}/*"
          }
        }
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_role.name
}

# Fargate Profiles

resource "aws_eks_fargate_profile" "fp_default" {
  fargate_profile_name   = "fp-default"
  cluster_name           = aws_eks_cluster.cluster.name
  subnet_ids             = aws_subnet.private[*].id
  pod_execution_role_arn = aws_iam_role.fargate_role.arn

  selector {
    namespace = "default"
  }
  selector {
    namespace = "kube-system"
  }

  depends_on = [
    aws_iam_role_policy_attachment.fargate_role_policy
  ]
}

# Connect to created EKS cluster

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.cluster.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Update pod annotation of coredns deployment to enable fargate nodes

resource "kubernetes_annotations" "coredns_pods_annotation" {
  api_version = "apps/v1"
  kind        = "Deployment"
  depends_on = [
    aws_eks_fargate_profile.fp_default
  ]
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }
  force = true
  template_annotations = {
    "eks.amazonaws.com/compute-type" = "fargate"
  }
}

# EKS Cluster Addons

resource "aws_eks_addon" "addons" {
  for_each     = local.cluster_addons
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = each.key
  timeouts {
    create = each.value
  }
  depends_on = [
    kubernetes_annotations.coredns_pods_annotation
  ]
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

module "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller_addon ? 1 : 0

  source = "../aws-eks-lbc-addon"

  application_name = var.application_name
  region           = var.region

  cluster_endpoint       = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = aws_eks_cluster.cluster.certificate_authority[0].data
  cluster_token          = data.aws_eks_cluster_auth.cluster.token

  cluster_name        = aws_eks_cluster.cluster.name
  cluster_oidc_issuer = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  vpc_id              = aws_vpc.default.id

  depends_on = [
    aws_eks_addon.addons
  ]
}
