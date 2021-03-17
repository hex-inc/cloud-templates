output "cert_verification" {
    value = aws_acm_certificate.cert.domain_validation_options
}