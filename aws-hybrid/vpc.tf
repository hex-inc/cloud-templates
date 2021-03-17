data "aws_availability_zones" "available" {
}

locals {
  database_subnets = ["10.35.201.0/24", "10.35.202.0/24", "10.35.203.0/24"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.0"

  name             = var.name
  cidr             = "10.35.0.0/16"
  azs              = data.aws_availability_zones.available.names
  database_subnets = local.database_subnets

  create_database_subnet_group = true
}

resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = var.hex_vpc_id
  peer_owner_id = var.hex_account_id

  tags = {
    Name = "VPC peering connection to Hex from ${var.name} hosted solution"
    Side = "Requester"
  }
}

resource "aws_route" "peer" {
  count                     = length(local.database_subnets)
  depends_on                = [module.vpc]
  route_table_id            = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
