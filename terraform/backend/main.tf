resource "aws_s3_bucket" "data_s3_bucket" {
  bucket = var.s3_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

resource "aws_dynamodb_table" "terraform_state_lock_table" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.data_s3_key.arn 
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true 
  }

  tags = var.tags
}

resource "aws_kms_key" "data_s3_key" {
  description             = "Data S3 key used to encrypt bucket objects"
  deletion_window_in_days = 10
  tags                    = var.tags 
  
  enable_key_rotation     = true
}

resource "aws_kms_alias" "data_s3_key_alias" {
  name          = "alias/s3/${var.s3_bucket_name}"
  target_key_id = aws_kms_key.data_s3_key.key_id
}
