resource "aws_kms_key" "cloudwatch" {
  description         = "Encryption key for Cloudwatch logs"
  enable_key_rotation = true

  policy = data.aws_iam_policy_document.cloudwatch.json

  tags = {
    "hex-deployment" = var.name
  }
}

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.aws_arn_identifier}:iam:::root"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${local.aws_arn_identifier}:logs:${var.region}::log-group:eks-${var.name}-log-group"]
    }

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/${var.name}/cloudwatch"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

module "cloudwatch-logs" {
  source            = "./modules/cloudwatch-logs"
  namespace         = "eks"
  stage             = var.name
  retention_in_days = 90
  kms_key_arn       = aws_kms_key.cloudwatch.arn
}

resource "helm_release" "fluentd-cloudwatch" {
  name    = "fluentd-cloudwatch"
  chart   = "fluentd-cloudwatch"
  url     = "https://charts.helm.sh/incubator"
  version = "0.13.0"

  values = [<<EOF
awsRegion: ${var.region}
awsAccessKeyId: ${aws_iam_access_key.fluentd.id}
awsSecretAccessKey: ${aws_iam_access_key.fluentd.secret}
logGroupName: ${module.cloudwatch-logs.log_group_name}
rbac:
  create: true
EOF
  ]
}
