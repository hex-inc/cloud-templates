# We have to append a random key because bucket ids must be globally unique
resource "random_string" "files-s3-bucket-id" {
  length  = 16
  special = false
  upper   = false
}

locals {
  files_bucket_name = "${var.name}-files-${random_string.files-s3-bucket-id.result}"
}

resource "aws_iam_user" "files-s3" {
  force_destroy = "false"
  name          = "${var.name}-files-s3"
  path          = "/"
}

resource "aws_iam_access_key" "files-s3" {
  user    = aws_iam_user.files-s3.name
  pgp_key = var.pgp_key
}

resource "aws_kms_grant" "files-s3" {
  name              = "${var.name}-files-s3-kms"
  key_id            = aws_kms_key.files-s3.key_id
  grantee_principal = aws_iam_user.files-s3.arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}

resource "aws_kms_key" "files-s3" {
  description         = "${var.name} Encryption key for files S3"
  enable_key_rotation = true

  tags = {
    "s3-bucket" = local.files_bucket_name
  }
}

resource "aws_kms_alias" "files-s3" {
  name          = "alias/${var.name}/files-s3"
  target_key_id = aws_kms_key.files-s3.key_id
}

data "aws_iam_policy_document" "allow-files-s3" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::${local.files_bucket_name}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.files-s3.arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.files_bucket_name}"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.files-s3.arn]
    }
  }
}

resource "aws_s3_bucket" "files" {
  bucket = local.files_bucket_name
  acl    = "private"

  tags = {
    Name = "Storage for files in Hex"
  }

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.files-s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  policy = data.aws_iam_policy_document.allow-files-s3.json
}
