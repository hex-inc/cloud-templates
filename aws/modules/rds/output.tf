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

output "rds_password_location" {
  value = aws_ssm_parameter.postgres-password.name
}

output "db_tunnel_id" {
  value = aws_instance.db-tunnel.id
}
