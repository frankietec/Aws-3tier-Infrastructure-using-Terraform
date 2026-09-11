resource "aws_ecr_repository" "bank_frontend" {
  name = "${var.environment}-bankfrontend"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "bank_backend_api" {
  name = "${var.environment}-bankbackendapi"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
