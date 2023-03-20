# AWS

data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../aws-eks-fargate/terraform.tfstate"
  }
}

provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_access_secret_key
  region     = data.terraform_remote_state.eks.outputs.region
}

data "aws_eks_cluster" "primary" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = data.aws_eks_cluster.primary.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.primary.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.primary.name]
      command     = "aws"
    }
  }
}

resource "helm_release" "eks_2048" {
  provider   = helm.eks
  name       = "k8s-2048"
  repository = "https://aseerkt.github.io/wf-charts"
  chart      = "wf-2048"

  dynamic "set" {
    for_each = {
      "replicaCount"                                                    = 5
      "ingress.enabled"                                                 = true
      "ingress.hosts[0].host"                                           = ""
      "ingress.hosts[0].paths[0].path"                                  = "/"
      "ingress.hosts[0].paths[0].pathType"                              = "Prefix"
      "ingress.className"                                               = "alb"
      "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"      = "internet-facing"
      "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type" = "ip"
    }
    content {
      name  = set.key
      value = set.value
    }
  }
}

# GKE

data "terraform_remote_state" "gke" {
  backend = "local"
  config = {
    path = "../gcp-gke-autopilot/terraform.tfstate"
  }
}

provider "google" {
  project = var.project_id
  region  = data.terraform_remote_state.gke.outputs.region
}

data "google_client_config" "provider" {}

data "google_container_cluster" "secondary" {
  name     = data.terraform_remote_state.gke.outputs.cluster_name
  location = data.terraform_remote_state.gke.outputs.region
}

provider "helm" {
  alias = "gke"
  kubernetes {
    host  = "https://${data.google_container_cluster.secondary.endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.secondary.master_auth[0].cluster_ca_certificate,
    )
  }
}

resource "helm_release" "gke_2048" {
  provider = helm.gke

  name       = "k8s-2048"
  repository = "https://aseerkt.github.io/wf-charts"
  chart      = "wf-2048"

  dynamic "set" {
    for_each = {
      "replicaCount"                                        = 5
      "ingress.enabled"                                     = true
      "ingress.hosts[0].host"                               = ""
      "ingress.hosts[0].paths[0].path"                      = "/"
      "ingress.hosts[0].paths[0].pathType"                  = "Prefix"
      "ingress.annotations.kubernetes\\.io/ingress\\.class" = "gce"
    }
    content {
      name  = set.key
      value = set.value
    }
  }
}
