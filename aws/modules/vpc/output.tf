output "vpc_id" {
  value = module.vpc.vpc_id
}

output "database_subnet_group" {
  value = module.vpc.database_subnet_group
}

output "private_subnets" {
  value = module.vpc.private_subnets
}
