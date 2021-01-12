module "ses" {
  source  = "cloudposse/ses/aws"
  version = "0.8.1"

  domain        = var.domain
  zone_id       = var.zone_id
  enabled       = true
  verify_dkim   = true
  verify_domain = true

  providers = {
    aws = aws.ses
  }
}

resource "aws_ssm_parameter" "postgres-password" {
  name  = "/${var.name}/ses/smtp-password"
  type  = "SecureString"
  value = module.ses.secret_access_key

  tags = {
    "hex-deployment" = var.name
  }

  providers = {
    aws = aws.main
  }
}
