data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.0"

  name             = var.name
  cidr             = "10.35.0.0/16"
  azs              = data.aws_availability_zones.available.names
  database_subnets = ["10.35.201.0/24", "10.35.202.0/24", "10.35.203.0/24"]

  create_database_subnet_group = true

  database_route_table_tags = {
    "hex/cluster" = var.name
  }
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


data "aws_route_tables" "peer" {
  vpc_id = module.vpc.vpc_id

  filter {
    name   = "tag:hex/cluster"
    values = [var.name]
  }

  depends_on = [module.vpc]
}

resource "aws_route" "peer" {
  for_each                  = data.aws_route_tables.peer.ids
  route_table_id            = each.value
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
