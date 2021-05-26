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
      smtp_username = module.ses.access_key_id
      smtp_password = module.ses.ses_smtp_password
    },
    backend = {
      "AWS_SECRET_ACCESS_KEY" = aws_iam_access_key.files-s3.secret
      "AWS_ACCESS_KEY_ID"     = aws_iam_access_key.files-s3.id
      bucket                  = local.files_bucket_name
    }
    cache = {
      "AWS_SECRET_ACCESS_KEY" = aws_iam_access_key.data-cache-s3.secret
      "AWS_ACCESS_KEY_ID"     = aws_iam_access_key.data-cache-s3.id
      bucket                  = local.cache_bucket_name
    }
    rds = {
      host     = aws_db_instance.hex.address
      port     = aws_db_instance.hex.port
      username = aws_db_instance.hex.username
      password = random_password.postgres-password.result
    }
  })
}
