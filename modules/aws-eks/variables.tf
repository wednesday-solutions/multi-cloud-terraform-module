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
  default     = "ap-south-1"
}

variable "cluster_addons" {
  type        = list(string)
  description = "EKS cluster addons"
  default     = ["vpc-cni", "kube-proxy", "coredns"]
}



