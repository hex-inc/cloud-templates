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

module "tgw" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "~> 1.0"

  name        = "hex-tgw"
  description = "Hex Transit Gateway"

  vpc_attachments = {
    # vpc = {
    #   vpc_id       = module.vpc.vpc_id
    #   subnet_ids   = module.vpc.database_subnets
    #   dns_support  = true
    #   ipv6_support = true

    #   tgw_routes = [
    #     {
    #       destination_cidr_block = "30.0.0.0/16"
    #     }
    #   ]
    # }
  }

  ram_allow_external_principals = true
  ram_principals                = [var.hex_account_id]
}
