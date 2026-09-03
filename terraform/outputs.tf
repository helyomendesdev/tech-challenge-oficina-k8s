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

output "alb_security_group_id" {
  description = "ID do Security Group do ALB interno."
  value       = aws_security_group.alb.id
}

output "alb_listener_arn" {
  description = "ARN do listener HTTP do ALB interno."
  value       = aws_lb_listener.http.arn
}

output "alb_arn" {
  description = "ARN do ALB interno."
  value       = aws_lb.internal.arn
}

output "alb_dns_name" {
  description = "DNS do ALB interno."
  value       = aws_lb.internal.dns_name
}

output "alb_target_group_arn" {
  description = "ARN do Target Group do EKS."
  value       = aws_lb_target_group.eks.arn
}

output "ecr_repository_url" {
  description = "URL do repositório ECR da API."
  value       = aws_ecr_repository.api.repository_url
}

output "eks_cluster_security_group_id" {
  description = "Security group que os nodes usam — e o que o RDS deve autorizar na 5432."
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}
