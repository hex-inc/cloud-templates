resource "aws_route53_zone" "hex" {
  name = var.domain_name
}

data "aws_elb_hosted_zone_id" "hex" {}

resource "aws_route53_record" "hex" {
  for_each = var.alb_url != null ? toset([var.alb_url]) : []
  name     = "${var.domain_name}."
  type     = "A"
  zone_id  = aws_route53_zone.hex.zone_id

  alias {
    name                   = each.value
    zone_id                = data.aws_elb_hosted_zone_id.hex.id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "hex-mx" {
  name    = "${var.domain_name}."
  type    = "MX"
  zone_id = aws_route53_zone.hex.zone_id
  records = ["10 feedback-smtp.${var.region}.amazonses.com"]
  ttl     = 600
}

resource "aws_route53_record" "hex-spf" {
  name    = "${var.domain_name}."
  type    = "TXT"
  zone_id = aws_route53_zone.hex.zone_id
  records = ["v=spf1 include:amazonses.com ~all"]
  ttl     = 600
}