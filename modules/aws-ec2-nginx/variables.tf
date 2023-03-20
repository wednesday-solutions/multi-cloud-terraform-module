variable "vpc_id" {
  type        = string
  description = "ID of VPC in which EC2 instance is created"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for EC2 instance"
}

variable "instance_name" {
  type        = string
  description = "EC2 Instance name"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "auto_create_security_group" {
  type        = bool
  description = "Auto create Security Group for SSH & HTTP access"
  default     = true
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security Group IDs (Only used if create_security_group is set to false)"
  default     = []
}


variable "nginx_conf" {
  type = object({
    port    = number
    servers = list(string)
  })
  description = "NGINX configuration"
}
