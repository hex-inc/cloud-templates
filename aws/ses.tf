module "ses-domain" {
  source  = "trussworks/ses-domain/aws"
  version = "~> 2.0.7"

  domain_name      = "${var.domain_name}."
  mail_from_domain = "${var.domain_name}."
  route53_zone_id  = aws_route53_zone.hex.zone_id
  dmarc_rua        = "dmarc-reports@hex.tech"

  enable_incoming_email = false
  enable_spf_record     = true

  // these are only used if `enable_incoming_email` is true
  from_addresses = ["notify@${var.domain_name}"]
  ses_rule_set   = "hex-ses-rule-set"
}

data "aws_iam_policy_document" "ses-smtp" {
  statement {
    effect = "Allow"
    actions = [
      "ses:SendRawEmail",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ses-smtp" {
  name = "ses-smtp"
  path = "/"

  policy = data.aws_iam_policy_document.ses-smtp.json
}

resource "aws_iam_user" "ses-smtp" {
  name = "ses-smtp-user"
}

resource "aws_iam_user_policy_attachment" "ses-smtp" {
  policy_arn = aws_iam_policy.ses-smtp.arn
  user       = aws_iam_user.ses-smtp.name
}

resource "aws_iam_access_key" "ses-smtp" {
  user = aws_iam_user.ses-smtp.name
}
