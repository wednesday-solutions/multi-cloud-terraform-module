variable "application_name" {
  type        = string
  description = "Name of application"
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
