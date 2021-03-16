data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70.0"

  name             = "Hex"
  cidr             = "10.0.0.0/16"
  azs              = data.aws_availability_zones.available.names
  private_subnets  = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
  public_subnets   = ["10.0.110.0/24", "10.0.120.0/24", "10.0.130.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/hex" = "shared"
    "kubernetes.io/role/elb"    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/hex"       = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}


resource "aws_vpc_peering_connection_accepter" "peer" {
  for_each                  = var.vpc_peering_id ? toset([var.vpc_peering_id]) : []
  vpc_peering_connection_id = each.value

  tags = {
    Side = "Accepter"
  }
}
