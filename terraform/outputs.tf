output "vpc_id" {
  description = "ID da VPC da aplicação"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
}
