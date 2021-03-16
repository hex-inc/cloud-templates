# We have to append a random key because bucket ids must be globally unique
resource "random_string" "logging-s3-bucket-id" {
  length  = 16
  special = false
  upper   = false
}

locals {
  logging_bucket_name = "${var.name}-logging-${random_string.logging-s3-bucket-id.result}"
}

resource "aws_kms_key" "logging-s3" {
  description         = "${var.name} Encryption key for logging S3"
  enable_key_rotation = true

  tags = {
    "s3-bucket" = local.logging_bucket_name
  }
}

resource "aws_kms_alias" "logging-s3" {
  name          = "alias/${var.name}/logging-s3"
  target_key_id = aws_kms_key.logging-s3.key_id
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = local.logging_bucket_name
  acl    = "log-delivery-write"

  tags = {
    Name = "Logging for s3 buckets in ${var.name}"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.logging-s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
