module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name = var.domain_name
  zone_id     = aws_route53_zone.hex.zone_id

  tags = {
    Name = var.domain_name
  }
}
