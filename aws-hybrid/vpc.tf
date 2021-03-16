data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.0"

  name             = "Hex"
  cidr             = "10.35.0.0/16"
  azs              = data.aws_availability_zones.available.names
  private_subnets  = ["10.35.10.0/24", "10.35.20.0/24", "10.35.30.0/24"]
  public_subnets   = ["10.35.110.0/24", "10.35.120.0/24", "10.35.130.0/24"]
  database_subnets = ["10.35.201.0/24", "10.35.202.0/24", "10.35.203.0/24"]

  create_database_subnet_group       = true
  create_database_subnet_route_table = true
  enable_ipv6                        = true
}

locals {
  vpc_peers = var.peer_vpc_id != null && var.peer_owner_id != null ? {
    "${var.peer_vpc_id}" = var.peer_owner_id
  } : {}
}

resource "aws_vpc_peering_connection" "peer" {
  for_each      = local.vpc_peers
  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = each.key
  peer_owner_id = each.value

  tags = {
    Side = "Requester"
  }
}
