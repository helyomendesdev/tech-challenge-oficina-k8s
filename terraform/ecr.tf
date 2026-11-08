resource "aws_ecr_repository" "api" {
  name = "oficina-api"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "oficina-api"
  }
}

resource "aws_ecr_repository" "os" {
  name = "oficina-os"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name      = "oficina-os"
    Component = "os"
  }
}

resource "aws_ecr_repository" "execution" {
  name = "oficina-execution"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name      = "oficina-execution"
    Component = "execution"
  }
}

resource "aws_ecr_repository" "billing" {
  name = "oficina-billing"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name      = "oficina-billing"
    Component = "billing"
  }
}
