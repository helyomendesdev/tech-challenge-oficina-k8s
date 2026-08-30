resource "aws_ecr_repository" "api" {
  name = "oficina-api"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "oficina-api"
  }
}
