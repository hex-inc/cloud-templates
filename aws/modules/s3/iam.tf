resource "aws_iam_user" "backend" {
  force_destroy = "false"
  name          = "${local.safe_name}-backend"
  path          = "/"

  tags = {
    "hex-deployment" = var.name
  }
}

resource "aws_iam_access_key" "backend" {
  user = aws_iam_user.backend.name
}

resource "aws_ssm_parameter" "access-key" {
  name  = "/${var.name}/${var.bucket_name}/access-key"
  type  = "SecureString"
  value = aws_iam_access_key.backend.id

  tags = {
    "hex-deployment" = var.name
  }
}

resource "aws_ssm_parameter" "secret-key" {
  name  = "/${var.name}/${var.bucket_name}/secret-key"
  type  = "SecureString"
  value = aws_iam_access_key.backend.secret

  tags = {
    "hex-deployment" = var.name
  }
}

resource "aws_kms_grant" "backend" {
  name              = "${local.safe_name}-s3-kms"
  key_id            = aws_kms_key.s3.key_id
  grantee_principal = aws_iam_user.backend.arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}
