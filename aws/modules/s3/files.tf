locals {
  files-bucket-name = "${var.name}-files-${random_string.s3-bucket-id.result}"
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
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.name}/s3"
  target_key_id = aws_kms_key.s3.key_id
}

data "aws_iam_policy_document" "files-allow-backend" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws-us-gov:s3:::${local.files-bucket-name}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.backend.arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws-us-gov:s3:::${local.files-bucket-name}"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.backend.arn]
    }
  }
}

resource "aws_s3_bucket" "files" {
  bucket = local.files-bucket-name
  acl    = "private"

  tags = {
    Name = "Files for ${var.name}"
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
