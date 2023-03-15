variable "project_id" {
  type        = string
  description = "Project ID"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "GKE cluster region"
}

variable "application_name" {
  type        = string
  description = "Application name"
}


variable "subnet_cidr_range" {
  type        = string
  description = "IP CIDR range for subnetwork"
}
