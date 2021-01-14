locals {
  is_govcloud        = length(regexall("us-gov", var.region)) > 0 ? true : false
  aws_arn_identifier = local.is_govcloud ? "aws-us-gov" : "aws"
}
