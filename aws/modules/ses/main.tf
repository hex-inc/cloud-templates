module "ses" {
  source  = "cloudposse/ses/aws"
  version = "~> 0.18"

  name          = var.name
  domain        = var.domain
  zone_id       = var.zone_id
  enabled       = true
  verify_dkim   = true
  verify_domain = true
}

resource "aws_ssm_parameter" "smtp-password" {
  name  = "/${var.name}/ses/smtp-password"
  type  = "SecureString"
  value = module.ses.secret_access_key

  tags = {
    "hex-deployment" = var.name
  }
}
