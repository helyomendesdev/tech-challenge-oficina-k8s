variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_link_security_group_id" {
  description = "ID do Security Group utilizado pelo VPC Link."
  type        = string
}
