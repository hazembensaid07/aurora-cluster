# VPC
resource "aws_vpc" "aurora-vpc" {
  cidr_block = var.vpc_cidr
  #enable dns resolution in the vpc 
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "aurora-vpc"

  }
}
# Internet Gateway for Public Subnet to allow ressources in the public subnet to connect to the internet
resource "aws_internet_gateway" "demo-ig" {
  vpc_id = aws_vpc.aurora-vpc.id
  tags = {
    Name = "aurora-vpc-internet-gateway"

  }
}
# Public subnet create public subnets based on the length of the array of cidr given 
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  vpc_id                  = aws_vpc.aurora-vpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "aurora-vpc-public-subnets"

  }
}
# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.aurora-vpc.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "aurora-vpc-private-subnets"

  }
}

#a route table to route network traffic to public subnet
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.aurora-vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-ig.id
  }

  tags = {
    Name = "public-route-table"
  }
}
#associate route table with the public subnet 
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public-route-table.id
}
# an elastic ip adress to be attached to a nat gateway 
resource "aws_eip" "ip" {
  vpc = true
  tags = {
    Name = "nat-elastic-ip"
  }
}

#create a nat gateway to allow resources in the private subnet access the internet 
resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.ip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 1)
  tags = {
    Name = "nat-gateway"
  }
}

#a route table to route network traffic for ressources in the private subnet 
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.aurora-vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gateway.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private-route-table.id
}

