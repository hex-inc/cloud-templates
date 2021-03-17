output "nameservers" {
  value = aws_route53_zone.hex.name_servers
}