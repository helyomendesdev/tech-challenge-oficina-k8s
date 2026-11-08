variable "aws_region" {
  description = "Região AWS do bucket de state."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Nome globalmente único do bucket S3 de Terraform State."
  type        = string
}
