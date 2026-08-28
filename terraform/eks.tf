resource "aws_eks_cluster" "main" {
  name     = "oficina-eks"
  role_arn = var.eks_cluster_role_arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]

    security_group_ids = [
      aws_security_group.eks.id
    ]

    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    Name = "oficina-eks"
  }
}
