resource "aws_iam_user" "backend" {
  force_destroy = "false"
  name          = "${local.name}-backend"
  path          = "/"

  tags = {
    "hex-deployment" = local.name
  }
}

resource "aws_iam_access_key" "backend" {
  user = aws_iam_user.backend.name
}

resource "aws_ssm_parameter" "access-key" {
  name  = "/${local.name}/access-key"
  type  = "SecureString"
  value = aws_iam_access_key.backend.id

  tags = {
    "hex-deployment" = local.name
  }
}

resource "aws_ssm_parameter" "secret-key" {
  name  = "/${local.name}/secret-key"
  type  = "SecureString"
  value = aws_iam_access_key.backend.secret

  tags = {
    "hex-deployment" = local.name
  }
}
