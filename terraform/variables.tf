variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_role_arn" {
  description = "ARN da IAM Role utilizada pelo cluster EKS."
  type        = string
}

variable "eks_node_role_arn" {
  description = "ARN da IAM Role utilizada pelos nodes do EKS."
  type        = string
}
