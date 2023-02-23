provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_access_secret_key
  region     = var.region
}

# Cloudformation Stack for Cluster VPC and Subnets

resource "aws_cloudformation_stack" "eks_vpc_stack" {
  name         = "${var.application_name}-eks-cf-stack"
  template_url = "https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml"
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
    subnet_ids = split(",", aws_cloudformation_stack.eks_vpc_stack.outputs["SubnetIds"])
  }
}

# EKS Cluster Addons

resource "aws_eks_addon" "cluster" {
  for_each     = toset(var.cluster_addons)
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = each.key
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

resource "aws_iam_role_policy_attachment" "fargate_role" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_role.name
}

# VPC private subnets

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [aws_cloudformation_stack.eks_vpc_stack.outputs["VpcId"]]
  }

  # Cloudformation create private subnets with the following tags
  tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# Fargate Profiles

resource "aws_eks_fargate_profile" "fp-default" {
  fargate_profile_name   = "fp-default"
  cluster_name           = aws_eks_cluster.cluster.name
  subnet_ids             = toset(data.aws_subnets.private.ids)
  pod_execution_role_arn = aws_iam_role.fargate_role.arn

  selector {
    namespace = "default"
  }
}

resource "aws_eks_fargate_profile" "coredns" {
  fargate_profile_name   = "CoreDNS"
  cluster_name           = aws_eks_cluster.cluster.name
  subnet_ids             = toset(data.aws_subnets.private.ids)
  pod_execution_role_arn = aws_iam_role.fargate_role.arn
  selector {
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kube-dns"
    }
  }
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
    aws_eks_fargate_profile.coredns
  ]
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }
  template_annotations = {
    "eks.amazonaws.com/compute-type" = null
  }
}

