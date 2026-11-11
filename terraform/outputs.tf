output "vpc_id" {
  description = "ID da VPC da aplicação"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "Bloco CIDR da VPC compartilhada."
  value       = aws_vpc.main.cidr_block
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

output "ecr_repository_urls" {
  description = "URLs dos repositórios ECR compartilhados, indexadas pelo componente."
  value = {
    api       = aws_ecr_repository.api.repository_url
    os        = aws_ecr_repository.os.repository_url
    execution = aws_ecr_repository.execution.repository_url
    billing   = aws_ecr_repository.billing.repository_url
  }
}

output "eks_cluster_name" {
  description = "Nome do cluster EKS compartilhado."
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint do cluster EKS compartilhado."
  value       = aws_eks_cluster.main.endpoint
}

output "sqs_queue_urls" {
  description = "URLs das filas SQS da Saga, indexadas pelo nome lógico."
  value = {
    for _, queue in aws_sqs_queue.saga : queue.name => queue.url
  }
}

output "sqs_queue_arns" {
  description = "ARNs das filas SQS da Saga, indexadas pelo nome lógico."
  value = {
    for _, queue in aws_sqs_queue.saga : queue.name => queue.arn
  }
}

output "sqs_dlq_urls" {
  description = "URLs das DLQs da Saga, indexadas pelo nome lógico."
  value = {
    for _, queue in aws_sqs_queue.saga_dlq : queue.name => queue.url
  }
}

output "sqs_dlq_arns" {
  description = "ARNs das DLQs da Saga, indexadas pelo nome lógico."
  value = {
    for _, queue in aws_sqs_queue.saga_dlq : queue.name => queue.arn
  }
}

output "eks_cluster_security_group_id" {
  description = "Security group que os nodes usam — e o que o RDS deve autorizar na 5432."
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}
