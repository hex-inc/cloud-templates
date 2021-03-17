resource "aws_secretsmanager_secret" "hex-secrets" {
  name = "${var.name}-secrets"
}

resource "aws_secretsmanager_secret_version" "hex-secrets" {
  secret_id = aws_secretsmanager_secret.hex-secrets.id
  secret_string = jsonencode({
    eks = {
      "AWS_SECRET_ACCESS_KEY" = aws_iam_access_key.eks-user.secret
      "AWS_ACCESS_KEY_ID"     = aws_iam_access_key.eks-user.id
      cluster                 = module.eks.cluster_id
    },
    smtp = {
        smtp_username     = aws_iam_access_key.ses-smtp.id
    smtp_password     = aws_iam_access_key.ses-smtp.ses_smtp_password_v4
      smtp_from_address = "notify@${var.domain_name}"
    }
  })
}
