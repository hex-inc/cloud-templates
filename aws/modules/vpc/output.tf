output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "database_subnet_group" {
  value = module.vpc.database_subnet_group
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_ips" {
  value = module.vpc.nat_public_ips
}
