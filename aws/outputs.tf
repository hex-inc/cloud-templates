output "nameservers" {
  value = aws_route53_zone.hex.name_servers
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "region" {
  value = var.region
}

output "vpc_cidr" {
  value = local.cidr
}

output "eks_cidr_blocks" {
  value = local.private_subnets
}

output "acm_certificate_arn" {
  value = module.acm.acm_certificate_arn
}