output "vpc_id" {
  value = aws_vpc.default.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "security_group_id" {
  value = aws_security_group.control_plane_sg.id
}
