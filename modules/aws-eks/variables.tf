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

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR IP address block"
}


variable "public_subnets" {
  description = "Public subnet configuration"
  type = list(object({
    name              = string
    availability_zone = string
    cidr_block        = string
  }))
}

variable "private_subnets" {
  description = "Private subnet configuration"
  type = list(object({
    name              = string
    availability_zone = string
    cidr_block        = string
  }))
}
