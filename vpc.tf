resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name             = local.name
    "hex-deployment" = local.name
  }
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name             = local.name
    "hex-deployment" = local.name
  }
}

module "public-subnet-us-east-2a" {
  source              = "./modules/public_subnet"
  availability_zone   = "us-east-2a"
  cidr_block          = "10.0.0.0/24"
  internet_gateway_id = aws_internet_gateway.internet-gateway.id
  name                = local.name
  vpc_id              = aws_vpc.vpc.id
}
module "public-subnet-us-east-2b" {
  source              = "./modules/public_subnet"
  availability_zone   = "us-east-2b"
  cidr_block          = "10.0.10.0/24"
  internet_gateway_id = aws_internet_gateway.internet-gateway.id
  name                = local.name
  vpc_id              = aws_vpc.vpc.id
}
module "public-subnet-us-east-2c" {
  source              = "./modules/public_subnet"
  availability_zone   = "us-east-2c"
  cidr_block          = "10.0.20.0/24"
  internet_gateway_id = aws_internet_gateway.internet-gateway.id
  name                = local.name
  vpc_id              = aws_vpc.vpc.id
}
