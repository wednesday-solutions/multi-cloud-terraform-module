variable "aws_access_key_id" {
  type        = string
  description = "AWS Access Key ID"
  sensitive   = true
}

variable "aws_access_secret_key" {
  type        = string
  description = "AWS Access Secret Key"
  sensitive   = true
}

variable "application_name" {
  type        = string
  description = "Name of application"
}

# TODO:// regions for multi region deployment
variable "region" {
  type        = string
  description = "AWS region"
}

variable "cluster_addons" {
  type        = map(string)
  description = "EKS cluster addons"
  default     = { "vpc-cni" = "5m", "kube-proxy" = "5m", "coredns" = "30m" }
}



