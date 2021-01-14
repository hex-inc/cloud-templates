output "access_key_id" {
  value = module.ses.access_key_id
}

output "secret_key_location" {
  value = aws_ssm_parameter.smtp-password.name
}
