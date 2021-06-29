resource "aws_route53_zone" "hex" {
  name = var.domain_name
}

data "aws_elb_hosted_zone_id" "hex" {}

resource "aws_route53_record" "hex" {
  count   = var.alb_url != null ? 1 : 0
  name    = "${var.domain_name}."
  type    = "A"
  zone_id = aws_route53_zone.hex.zone_id

  alias {
    name                   = var.alb_url
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