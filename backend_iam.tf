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
