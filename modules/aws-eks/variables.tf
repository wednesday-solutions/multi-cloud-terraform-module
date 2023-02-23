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

variable "aws_profile" {
  type        = string
  description = "AWS profile"
  default     = "default"
}

variable "application_name" {
  type        = string
  description = "Name of application"
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "ap-south-1"
}



