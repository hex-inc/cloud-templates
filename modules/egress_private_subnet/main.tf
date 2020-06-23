
resource "aws_subnet" "subnet" {
  cidr_block        = var.cidr_block
  availability_zone = var.availability_zone

  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_eip" "nat-eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_route_table" "route-table" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway.id
  }

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_route_table_association" "router-table-association" {
  route_table_id = aws_route_table.route-table.id
  subnet_id      = aws_subnet.subnet.id
}
