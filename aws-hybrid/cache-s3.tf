# We have to append a random key because bucket ids must be globally unique
resource "random_string" "cache-s3-bucket-id" {
  length  = 16
  special = false
  upper   = false
}

locals {
  cache_bucket_name = "${var.name}-cache-${random_string.cache-s3-bucket-id.result}"
}

resource "aws_iam_user" "data-cache-s3" {
  force_destroy = "false"
  name          = "${var.name}-data-cache-s3"
  path          = "/"
}

resource "aws_iam_access_key" "data-cache-s3" {
  user    = aws_iam_user.data-cache-s3.name
  pgp_key = var.pgp_key
}

resource "aws_kms_grant" "data-cache-s3" {
  name              = "${var.name}-cache-s3-kms"
  key_id            = aws_kms_key.cache-s3.key_id
  grantee_principal = aws_iam_user.data-cache-s3.arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}

resource "aws_kms_key" "cache-s3" {
  description         = "${var.name} Encryption key for cache S3"
  enable_key_rotation = true

  tags = {
    "s3-bucket" = local.cache_bucket_name
  }
}

resource "aws_kms_alias" "cache-s3" {
  name          = "alias/${var.name}/cache-s3"
  target_key_id = aws_kms_key.cache-s3.key_id
}

data "aws_iam_policy_document" "allow-data-cache-s3" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::${local.cache_bucket_name}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.data-cache-s3.arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.cache_bucket_name}"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.data-cache-s3.arn]
    }
  }
}

resource "aws_s3_bucket" "cache" {
  bucket = local.cache_bucket_name
  acl    = "private"

  tags = {
    Name = "Storage for cache in ${var.name}"
  }

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/"
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "transition"
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  lifecycle_rule {
    id      = "expiration"
    enabled = true

    expiration {
      days = 90
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.cache-s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  policy = data.aws_iam_policy_document.allow-data-cache-s3.json
}

resource "aws_s3_bucket_public_access_block" "files" {
  bucket                  = aws_s3_bucket.files.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
