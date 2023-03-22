locals {
  cluster_addons = { "vpc-cni" = "5m", "kube-proxy" = "5m", "coredns" = "30m" }
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
    security_group_ids      = var.security_group_ids
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
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
  subnet_ids             = var.private_subnet_ids
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

provider "kubernetes" {
  host                   = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.name]
    command     = "aws"
  }
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
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

module "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller_addon ? 1 : 0

  source = "../aws-eks-lbc-addon"

  application_name = var.application_name
  region           = var.region

  cluster_name = aws_eks_cluster.cluster.name

  depends_on = [
    aws_eks_addon.addons
  ]
}
