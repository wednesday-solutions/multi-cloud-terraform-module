variable "project_id" {
  type        = string
  description = "Project ID"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "GKE cluster region"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name"
}
