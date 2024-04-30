/*
 * VPC
 */
resource "aws_vpc" "eval_sleuth" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eval_sleuth"
  }
}

resource "aws_internet_gateway" "eval_sleuth" {
  vpc_id = aws_vpc.eval_sleuth.id
}

module "eval_sleuth_sg" {
  source      = "./module/security_group"
  name        = "module-sg"
  vpc_id      = aws_vpc.eval_sleuth.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

/*
 * Public
 */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eval_sleuth.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.eval_sleuth.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_eip" "nat_gateway_0" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.eval_sleuth]
}

resource "aws_eip" "nat_gateway_1" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.eval_sleuth]
}

resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  depends_on    = [aws_internet_gateway.eval_sleuth]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.eval_sleuth]
}

resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.eval_sleuth.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.eval_sleuth.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2c"
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

/*
 * Private
 */
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.eval_sleuth.id
}

resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.eval_sleuth.id
  cidr_block              = "10.0.65.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.eval_sleuth.id
  cidr_block              = "10.0.66.0/24"
  availability_zone       = "us-west-2c"
  map_public_ip_on_launch = false
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.eval_sleuth.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.eval_sleuth.id
}

resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}