resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.vpc_name }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "tf-igw" }
}
# Public Subnet
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index].cidr
  availability_zone       = var.public_subnets[count.index].az
  map_public_ip_on_launch = true
  tags                    = { Name = var.public_subnets[count.index].name }
}
# Isolated Subnet
resource "aws_subnet" "isolated" {
  count             = length(var.isolated_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.isolated_subnets[count.index].cidr
  availability_zone = var.isolated_subnets[count.index].az
  tags              = { Name = var.isolated_subnets[count.index].name }
}
# Route table cho public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "tf-public-route-table" }
}
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
# Route table cho isolated subnet
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "tf-isolated-route-table" }
}
resource "aws_route_table_association" "isolated_assoc" {
  count          = length(aws_subnet.isolated)
  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated.id
}
