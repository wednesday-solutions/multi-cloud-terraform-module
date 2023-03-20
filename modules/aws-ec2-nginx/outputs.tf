output "aws_instance_public_dns" {
  value     = aws_instance.nginx.public_dns
  sensitive = true
}

output "private_key" {
  value     = tls_private_key.nginx_instance.private_key_pem
  sensitive = true
}
