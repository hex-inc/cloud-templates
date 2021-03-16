output "vpc_peering_id" {
  value = [for peer in aws_vpc_peering_connection.peer : peer.id]
}
