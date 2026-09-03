resource "aws_security_group" "alb" {
  name        = "oficina-alb-sg"
  description = "Security group do ALB interno"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "oficina-alb-sg"
  }
}

resource "aws_security_group" "eks" {
  name        = "oficina-eks-sg"
  description = "Security group dos recursos do EKS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "oficina-eks-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_vpc" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = aws_vpc.main.cidr_block
  from_port   = 8000
  to_port     = 8000
  ip_protocol = "tcp"

  description = "Acesso ao listener do ALB a partir da VPC"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_nodes" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id

  from_port   = 30080
  to_port     = 30080
  ip_protocol = "tcp"

  description = "ALB para o NodePort da aplicacao"
}

# Os nodes de um managed node group sem launch template recebem o cluster
# security group criado pelo proprio EKS, nao o aws_security_group.eks — este
# fica anexado as ENIs do control plane. A regra precisa ir no SG dos nodes.
resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  security_group_id            = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.alb.id

  from_port   = 30080
  to_port     = 30080
  ip_protocol = "tcp"

  description = "NodePort a partir do ALB"
}

resource "aws_vpc_security_group_egress_rule" "eks_https" {
  security_group_id = aws_security_group.eks.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Permite saida HTTPS para servicos externos como New Relic"
}
