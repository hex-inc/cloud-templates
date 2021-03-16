output "vpc_peering_id" {
  for_each = aws_vpc_peering_connection.peer
  value    = each.id
}
