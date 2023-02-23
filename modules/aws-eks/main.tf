provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_access_secret_key
  region     = var.region
}

data "aws_caller_identity" "current" {}


# Cloudformation Stack for Cluster VPC and Subnets

resource "aws_cloudformation_stack" "eks_vpc_stack" {
  name         = "${var.application_name}-eks-cf-stack"
  template_url = "https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml"
}


# EKS Cluster IAM Role

resource "aws_iam_role" "cluster_role" {
  name = "AmazonEKSClusterRole"
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
  depends_on = [
    aws_iam_role.cluster_role
  ]
}

# EKS Cluster

resource "aws_eks_cluster" "cluster" {
  name     = "${var.application_name}-cluster"
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    subnet_ids = split(",", aws_cloudformation_stack.eks_vpc_stack.outputs["SubnetIds"])
  }

  depends_on = [
    aws_cloudformation_stack.eks_vpc_stack
  ]
}

# Fargate Pod Execution Role

resource "aws_iam_role" "fargate_role" {
  name = "AmazonEKSPodExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:fargateprofile/${aws_eks_cluster.cluster.name}/*"
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

  depends_on = [
    aws_iam_role.fargate_role
  ]
}

# VPC private  subnets

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

  depends_on = [
    aws_eks_cluster.cluster
  ]
}

resource "aws_eks_fargate_profile" "core_dns" {
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
  depends_on = [
    aws_eks_cluster.cluster
  ]
}

# TODO:// should we keep this in terraform or not
resource "null_resource" "fargate_coredns_pods" {
  provisioner "local-exec" {
    when    = create
    command = "${path.module}/scripts/patch-coredns-compute-type.sh"
    environment = {
      CLUSTER_NAME = aws_eks_fargate_profile.core_dns.cluster_name
      REGION       = var.region
    }
  }
}


