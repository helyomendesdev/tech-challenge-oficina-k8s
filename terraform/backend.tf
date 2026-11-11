terraform {
  backend "s3" {
    key          = "shared/terraform.tfstate"
    use_lockfile = true
  }
}
