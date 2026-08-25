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
