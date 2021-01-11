locals {
  bucket-name        = "${var.name}-${var.bucket_name}-${random_string.s3-bucket-id.result}"
  is_govcloud        = length(regexall("us-gov", var.region)) > 0 ? true : false
  aws_arn_identifier = is_govcloud ? "aws-us-gov" : "aws"
}

# We have to append a random key because bucket ids must be globally unique
resource "random_string" "s3-bucket-id" {
  length  = 16
  special = false
  upper   = false
}

resource "aws_kms_key" "s3" {
  description         = "Encryption key for S3"
  enable_key_rotation = true

  tags = {
    "hex-deployment" = var.name
    "s3-bucket"      = var.bucket_name
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.name}/${var.bucket_name}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

data "aws_iam_policy_document" "files-allow-backend" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:${local.aws_arn_identifier}:s3:::${local.bucket-name}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.backend.arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:${local.aws_arn_identifier}:s3:::${local.bucket-name}"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.backend.arn]
    }
  }
}

resource "aws_s3_bucket" "files" {
  bucket = local.bucket-name
  acl    = "private"

  tags = {
    Name = "Storage for ${var.bucket_name} in ${var.name}"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  policy = data.aws_iam_policy_document.files-allow-backend.json
}
