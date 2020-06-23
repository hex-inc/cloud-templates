output "s3_bucket_name" {
  value = aws_s3_bucket.files.id
}

output "s3_bucket_region" {
  value = aws_s3_bucket.files.region
}

output "rds_host" {
  value = aws_db_instance.default.address
}

output "rds_port" {
  value = aws_db_instance.default.port
}

output "rds_database" {
  value = local.dbname
}

output "rds_username" {
  value = local.dbusername
}
