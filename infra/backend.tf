# Standard S3 backend for Terraform state
# NOTE: backend configuration cannot use variables. Replace the placeholder values below
# with your real S3 bucket/key/region before running `terraform init`.


terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "sam-osung-terraform-state-20260911"
    # Keep this key stable so Terraform continues using the existing state.
    key     = "bankapp/terraform.tfstate" # legacy state path; do not rename without migrating state
    region  = "us-east-1"                 # your AWS region
    encrypt = true
  }
}
