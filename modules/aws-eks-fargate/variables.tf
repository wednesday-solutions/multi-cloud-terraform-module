variable "application_name" {
  type        = string
  description = "Name of application"
}

# TODO:// regions for multi region deployment
variable "region" {
  type        = string
  description = "AWS region"
}

variable "enable_aws_load_balancer_controller_addon" {
  type        = bool
  default     = true
  description = "Enable AWS load balancer controller addon for current cluster"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Secuirity group IDs for cluster"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Priavte subnet IDs"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Priavte subnet IDs"
}
