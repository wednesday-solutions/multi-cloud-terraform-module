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

variable "enable_aws_load_balancer_controller_addon" {
  type        = bool
  default     = true
  description = "Enable AWS load balancer controller addon for current cluster"
}
