output "state_bucket_name" {
  description = "Bucket S3 usado pelos Terraform States deste ambiente."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN do bucket S3 dos Terraform States."
  value       = aws_s3_bucket.terraform_state.arn
}

output "state_access_policy_json" {
  description = "Policy IAM mínima para leitura/escrita/locking dos States deste repositório."
  value       = data.aws_iam_policy_document.state_access.json
}
