
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-files-buckets-1"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
