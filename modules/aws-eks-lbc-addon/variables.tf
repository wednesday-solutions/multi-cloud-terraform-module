variable "application_name" {
  type        = string
  description = "Application name"
}

variable "region" {
  type        = string
  description = "Cluster region"
}

variable "cluster_oidc_issuer" {
  type        = string
  description = "OIDC issuer URL"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "vpc_id" {
  type        = string
  description = "Cluster VPC ID"
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint"
}
variable "cluster_ca_certificate" {
  type        = string
  description = "EKS cluster CA ceritificate"
}
variable "cluster_token" {
  type        = string
  description = "EKC cluster token"
}
