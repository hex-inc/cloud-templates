resource "aws_route53_zone" "main" {
  name = var.domain

  tags = {
    "hex-deployment" = var.name
  }
}

module "hex-site-cloudfront-cert" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name = var.domain
  zone_id     = aws_route53_zone.main.zone_id

  subject_alternative_names = []

  tags = {
    Name             = var.domain
    "hex-deployment" = var.name
  }
}

data "aws_elb_hosted_zone_id" "main" {}

resource "aws_route53_record" "main" {
  count   = var.alb_hostname != null ? 1 : 0
  name    = var.domain
  type    = "A"
  zone_id = aws_route53_zone.main.zone_id

  alias {
    name                   = var.alb_hostname
    zone_id                = data.aws_elb_hosted_zone_id.main.id
    evaluate_target_health = false
  }
}
