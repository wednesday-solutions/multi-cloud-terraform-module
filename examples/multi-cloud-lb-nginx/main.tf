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

provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.primary.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.primary.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.primary.name]
    command     = "aws"
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

provider "kubernetes" {
  alias = "gke"
  host  = "https://${data.google_container_cluster.secondary.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.secondary.master_auth[0].cluster_ca_certificate,
  )
}

# Sample application

data "terraform_remote_state" "game_2048" {
  backend = "local"
  config = {
    path = "../multi-cloud-sample-app/terraform.tfstate"
  }
}

data "kubernetes_ingress_v1" "eks_ingress_2048" {
  provider = kubernetes.eks
  metadata {
    name = data.terraform_remote_state.game_2048.outputs.ingress_name
  }
}

data "kubernetes_ingress_v1" "gke_ingress_2048" {
  provider = kubernetes.gke
  metadata {
    name = data.terraform_remote_state.game_2048.outputs.ingress_name
  }
}

module "ec2_nginx" {
  source = "../../modules/aws-ec2-nginx"

  vpc_id                     = data.terraform_remote_state.eks.outputs.vpc_id
  subnet_id                  = data.terraform_remote_state.eks.outputs.public_subnet_ids[0]
  instance_name              = "mc-nginx-lb"
  instance_type              = "t2.micro"
  auto_create_security_group = true
  nginx_conf = {
    port = 80
    servers = [
      data.kubernetes_ingress_v1.eks_ingress_2048.status.0.load_balancer.0.ingress.0.hostname,
      data.kubernetes_ingress_v1.gke_ingress_2048.status.0.load_balancer.0.ingress.0.ip
    ]
  }
}
