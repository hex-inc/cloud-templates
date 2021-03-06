locals {
  log_group_name = "eks-${var.name}-log-group"
}
resource "aws_cloudwatch_log_group" "default" {
  name              = local.log_group_name
  retention_in_days = 90
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

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
      identifiers = ["arn:${local.aws_arn_identifier}:iam::${data.aws_caller_identity.current.account_id}:root"]
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
      values   = ["arn:${local.aws_arn_identifier}:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}"]
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

# fluentd permissions
resource "aws_iam_user" "fluentd" {
  force_destroy = "false"
  name          = "fluentd-${var.name}"
  path          = "/"
}

resource "aws_iam_user_policy_attachment" "fluentd" {
  policy_arn = "arn:${local.aws_arn_identifier}:iam::aws:policy/CloudWatchAgentServerPolicy"
  user       = aws_iam_user.fluentd.name
}

resource "aws_iam_access_key" "fluentd" {
  user = aws_iam_user.fluentd.name
}

# TODO: migrate to naked fluentd (this is deprecated) + use the -cloudwatch docker image + pass these as fluentd config variables
resource "helm_release" "fluentd-cloudwatch" {
  name             = "fluentd-cloudwatch"
  chart            = "fluentd-cloudwatch"
  repository       = "https://charts.helm.sh/incubator"
  version          = "0.13.2"
  namespace        = "fluentd-cloudwatch"
  create_namespace = true

  set {
    name  = "awsRegion"
    value = var.region
  }

  set_sensitive {
    name  = "awsAccessKeyId"
    value = aws_iam_access_key.fluentd.id
  }

  set_sensitive {
    name  = "awsSecretAccessKey"
    value = aws_iam_access_key.fluentd.secret
  }

  set {
    name  = "logGroupName"
    value = local.log_group_name
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "image.tag"
    value = "v1.12-debian-cloudwatch-1"
  }
}
