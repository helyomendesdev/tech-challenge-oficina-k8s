terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_iam_policy_document" "state_access" {
  statement {
    sid       = "ListTerraformStateKeys"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.terraform_state.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "shared/terraform.tfstate",
        "shared/terraform.tfstate.tflock",
        "bootstrap/terraform.tfstate",
        "bootstrap/terraform.tfstate.tflock"
      ]
    }
  }

  statement {
    sid     = "ManageOnlyTerraformStateObjects"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "${aws_s3_bucket.terraform_state.arn}/shared/terraform.tfstate",
      "${aws_s3_bucket.terraform_state.arn}/shared/terraform.tfstate.tflock",
      "${aws_s3_bucket.terraform_state.arn}/bootstrap/terraform.tfstate",
      "${aws_s3_bucket.terraform_state.arn}/bootstrap/terraform.tfstate.tflock"
    ]
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = var.state_bucket_name
  force_destroy = false

  tags = {
    Name      = var.state_bucket_name
    Purpose   = "terraform-state"
    Component = "shared-infrastructure"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
