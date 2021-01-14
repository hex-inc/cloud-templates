output "s3_bucket_name" {
  value = aws_s3_bucket.files.id
}

output "s3_bucket_region" {
  value = aws_s3_bucket.files.region
}

output "s3_bucket_access_key_location" {
  value = aws_ssm_parameter.access-key.name
}

output "s3_bucket_secret_key_location" {
  value = aws_ssm_parameter.secret-key.name
}