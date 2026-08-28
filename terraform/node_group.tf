resource "aws_eks_node_group" "main" {
  cluster_name = aws_eks_cluster.main.name

  node_group_name = "oficina-eks-nodes"

  node_role_arn = var.eks_node_role_arn

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  instance_types = ["t3.micro"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  tags = {
    Name = "oficina-eks-nodes"
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}
