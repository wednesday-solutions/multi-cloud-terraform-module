resource "aws_security_group" "vpc_access" {
  count       = var.auto_create_security_group ? 1 : 0
  name        = "${var.instance_name}-sg"
  description = "Allow SSH & HTTP on port 80"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-ssh-public/${var.instance_name}"
  }
}

resource "tls_private_key" "nginx_instance" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  public_key = tls_private_key.nginx_instance.public_key_openssh

  tags = {
    Name = "rsa-private-key/${var.instance_name}"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "nginx" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = true

  key_name               = aws_key_pair.generated_key.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.auto_create_security_group ? [aws_security_group.vpc_access[0].id] : var.security_group_ids
  user_data              = templatefile("${path.module}/templates/setup-nginx.sh", var.nginx_conf)

  tags = {
    Name = var.instance_name
  }
}
