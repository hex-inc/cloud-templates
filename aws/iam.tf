# create iam users for connecting to EKS. Creating access keys/passwords is done manually via UI
resource "aws_iam_user" "eks-user" {
  for_each      = toset(jsondecode(var.eks_users))
  force_destroy = "false"
  name          = each.value
  path          = "/"
}

resource "aws_iam_user_policy_attachment" "eks-user" {
  for_each   = aws_iam_user.eks-user
  user       = each.value.name
  policy_arn = aws_iam_policy.eks-user.arn
}

# Allow users to connect to EKS
data "aws_iam_policy_document" "eks-user" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "eks:DescribeNodegroup",
      "eks:ListNodegroups",
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:AccessKubernetesApi",
      "ssm:GetParameter",
      "eks:ListUpdates",
      "eks:ListFargateProfiles",
    ]
  }
}

resource "aws_iam_policy" "eks-user" {
  description = "Allow user to use EKS clusters"
  name        = "eks-user"
  policy      = data.aws_iam_policy_document.eks-user.json
}

# Enforce MFA Policy
data "aws_iam_policy_document" "enforce-mfa" {
  statement {
    sid       = "AllowViewAccountInfo"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "iam:GetAccountPasswordPolicy",
      "iam:GetAccountSummary",
      "iam:ListVirtualMFADevices",
    ]
  }

  statement {
    sid       = "AllowManageOwnPasswords"
    effect    = "Allow"
    resources = ["arn:aws:iam::*:user/$${aws:username}"]

    actions = [
      "iam:ChangePassword",
      "iam:GetUser",
    ]
  }

  statement {
    sid       = "AllowManageOwnAccessKeys"
    effect    = "Allow"
    resources = ["arn:aws:iam::*:user/$${aws:username}"]

    actions = [
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:ListAccessKeys",
      "iam:UpdateAccessKey",
    ]
  }

  statement {
    sid       = "AllowManageOwnSigningCertificates"
    effect    = "Allow"
    resources = ["arn:aws:iam::*:user/$${aws:username}"]

    actions = [
      "iam:DeleteSigningCertificate",
      "iam:ListSigningCertificates",
      "iam:UpdateSigningCertificate",
      "iam:UploadSigningCertificate",
    ]
  }

  statement {
    sid       = "AllowManageOwnSSHPublicKeys"
    effect    = "Allow"
    resources = ["arn:aws:iam::*:user/$${aws:username}"]

    actions = [
      "iam:DeleteSSHPublicKey",
      "iam:GetSSHPublicKey",
      "iam:ListSSHPublicKeys",
      "iam:UpdateSSHPublicKey",
      "iam:UploadSSHPublicKey",
    ]
  }

  statement {
    sid       = "AllowManageOwnGitCredentials"
    effect    = "Allow"
    resources = ["arn:aws:iam::*:user/$${aws:username}"]

    actions = [
      "iam:CreateServiceSpecificCredential",
      "iam:DeleteServiceSpecificCredential",
      "iam:ListServiceSpecificCredentials",
      "iam:ResetServiceSpecificCredential",
      "iam:UpdateServiceSpecificCredential",
    ]
  }

  statement {
    sid       = "AllowManageOwnVirtualMFADevice"
    effect    = "Allow"
    resources = ["arn:aws:iam::*:mfa/$${aws:username}"]

    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
    ]
  }

  statement {
    sid       = "AllowManageOwnUserMFA"
    effect    = "Allow"
    resources = ["arn:aws:iam::*:user/$${aws:username}"]

    actions = [
      "iam:DeactivateMFADevice",
      "iam:EnableMFADevice",
      "iam:ListMFADevices",
      "iam:ResyncMFADevice",
    ]
  }

  statement {
    sid       = "DenyAllExceptListedIfNoMFA"
    effect    = "Deny"
    resources = ["*"]

    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetSessionToken",
    ]

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "enforce-mfa" {
  name = "EnforceMFA"
  path = "/"

  policy = data.aws_iam_policy_document.enforce-mfa.json
}
