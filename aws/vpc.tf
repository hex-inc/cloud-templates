locals {
  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
  public_subnets  = ["10.0.110.0/24", "10.0.120.0/24", "10.0.130.0/24"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.70"

  name            = var.name
  cidr            = local.cidr
  azs             = data.aws_availability_zones.available.names
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/elb"            = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/internal-elb"   = "1"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  for_each = var.vpc_peering_id != null ? toset([var.vpc_peering_id]) : []

  vpc_peering_connection_id = each.value
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

data "aws_vpc_peering_connection" "peer" {
  for_each = var.vpc_peering_id != null ? toset([var.vpc_peering_id]) : []
  id       = each.value
}

resource "aws_route" "peer" {
  for_each                  = var.vpc_peering_id != null ? toset(module.vpc.private_route_table_ids) : []
  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc_peering_connection.peer[var.vpc_peering_id].cidr_block
  vpc_peering_connection_id = var.vpc_peering_id
}

