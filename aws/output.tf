# S3
output "files_s3_bucket_name" {
  value = module.s3.s3_bucket_name
}

output "files_s3_bucket_region" {
  value = module.s3.s3_bucket_region
}

output "files_s3_bucket_access_key_location" {
  value = module.s3.s3_bucket_access_key_location
}

output "files_s3_bucket_secret_key_location" {
  value = module.s3.s3_bucket_secret_key_location
}

output "cache-s3_bucket_name" {
  value = module.cache-s3.s3_bucket_name
}

output "cache_s3_bucket_region" {
  value = module.cache-s3.s3_bucket_region
}

output "cache_s3_bucket_access_key_location" {
  value = module.cache-s3.s3_bucket_access_key_location
}

output "cache_s3_bucket_secret_key_location" {
  value = module.cache-s3.s3_bucket_secret_key_location
}

# RDS

output "rds_host" {
  value = module.rds.rds_host
}

output "rds_port" {
  value = module.rds.rds_port
}

output "rds_database" {
  value = module.rds.rds_database
}

output "rds_username" {
  value = module.rds.rds_username
}

output "rds_password_location" {
  value = module.rds.rds_password_location
}

output "db_tunnel_id" {
  value = module.rds.db_tunnel_id
}

# VPC

output "public_ips" {
  value = module.vpc.public_ips
}

# Route 53

output "name_servers" {
  value = try(module.route53[0].public_ips, null)
}

# SES

output "smtp_host" {
  value = var.ses_enabled ? "email-smtp.${var.region}.amazonaws.com" : null
}

output "smtp_port" {
  value = var.ses_enabled ? 465 : null
}

output "smtp_username" {
  value = try(module.ses[0].access_key_id, null)
}

output "smtp_password_location" {
  value = try(module.ses[0].secret_key_location, null)
}
