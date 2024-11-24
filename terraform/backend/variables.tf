variable "aws_profile" {
  type        = string
  description = "AWS profile to be used to interact with AWS"
  default    = "aws-profile"
}
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
  default = "my-terraform-state-files-buckets-1"

}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table used for state locking."
  type        = string
  default = "terraform-lock-table"
}


variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {
    Project     = "MyProject"
    CreatedBy   = "Terraform"         
  }
}
