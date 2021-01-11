locals {
  is_govcloud        = length(regexall("us-gov", var.region)) > 0 ? true : false
  aws_arn_identifier = is_govcloud ? "aws-us-gov" : "aws"
}
