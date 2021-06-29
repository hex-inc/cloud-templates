module "ses" {
  source  = "cloudposse/ses/aws"
  version = "0.12.0"

  domain        = var.domain_name
  zone_id       = aws_route53_zone.hex.zone_id
  verify_dkim   = true
  verify_domain = true

  name = var.name
}