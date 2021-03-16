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
}

locals {
  vpc_peers = var.hex_vpc_id != null && var.hex_account_id != null ? {
    (var.hex_vpc_id) = var.hex_account_id
  } : {}
}

resource "aws_vpc_peering_connection" "peer" {
  for_each      = local.vpc_peers
  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = each.key
  peer_owner_id = each.value

  tags = {
    Name = "VPC peering connection to Hex from ${var.name} hosted solution"
    Side = "Requester"
  }
}
