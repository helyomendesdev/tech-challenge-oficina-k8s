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

resource "aws_vpc_security_group_ingress_rule" "alb_from_vpc_link" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = var.vpc_link_security_group_id

  from_port   = 8000
  to_port     = 8000
  ip_protocol = "tcp"

  description = "Permite acesso ao ALB a partir do VPC Link"
}

resource "aws_vpc_security_group_ingress_rule" "eks_from_alb" {
  security_group_id            = aws_security_group.eks.id
  referenced_security_group_id = aws_security_group.alb.id

  from_port   = 8000
  to_port     = 8000
  ip_protocol = "tcp"

  description = "Permite acesso ao EKS a partir do ALB"
}
