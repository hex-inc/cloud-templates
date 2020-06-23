locals {
  name = "${var.name}-public-${var.availability_zone}"
}

resource "aws_subnet" "subnet" {
  cidr_block              = var.cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  vpc_id = var.vpc_id

  tags = {
    Name                                = local.name
    "kubernetes.io/cluster/${var.name}" = "shared"
    "hex-deployment"                    = var.name
  }
}

resource "aws_route_table" "route-table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = {
    Name             = local.name
    "hex-deployment" = var.name
  }
}

resource "aws_route_table_association" "route-table-association" {
  route_table_id = aws_route_table.route-table.id
  subnet_id      = aws_subnet.subnet.id
}
