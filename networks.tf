##################
# VPC
##################
resource "aws_vpc" "vpc_eks" {
  cidr_block = var.vpc_cidr_block

  tags = var.eks_resource_general_tags
}

##################
# SUBNETS
##################
# Refer: https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html#load-balancer-sample-application

# Private subnets
resource "aws_subnet" "us-east-1a-private" {
  vpc_id            = aws_vpc.vpc_eks.id
  availability_zone = var.azs[0]
  cidr_block        = var.private_cidr_blocks[0]


  tags = merge({ "Name" : "${var.azs[0]}-private" }, var.private_lb_tags)
}

resource "aws_subnet" "us-east-1b-private" {
  vpc_id            = aws_vpc.vpc_eks.id
  availability_zone = var.azs[1]
  cidr_block        = var.private_cidr_blocks[1]

  tags = merge({ "Name" : "${var.azs[1]}-private" }, var.private_lb_tags)
}

# Public subnets
resource "aws_subnet" "us-east-1a-public" {
  vpc_id            = aws_vpc.vpc_eks.id
  availability_zone = var.azs[0]
  cidr_block        = var.public_cidr_blocks[0]

  map_public_ip_on_launch = true

  tags = merge({ "Name" : "${var.azs[0]}-public" }, var.public_lb_tags)
}

resource "aws_subnet" "us-east-1b-public" {
  vpc_id            = aws_vpc.vpc_eks.id
  availability_zone = var.azs[1]
  cidr_block        = var.public_cidr_blocks[1]

  map_public_ip_on_launch = true

  tags = merge({ "Name" : "${var.azs[1]}-public" }, var.public_lb_tags)
}

####################
# Internet Gateway
####################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_eks.id

  tags = var.igw_tags
}

####################
# NAT Gateway
####################

resource "aws_eip" "eip_nat" {
  tags = var.eip_tags
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip_nat.id

  # attach this to a public subnet
  subnet_id = aws_subnet.us-east-1a-public.id

  tags = var.nat_gw_tags

  depends_on = [aws_internet_gateway.igw]
}

####################
# Route Table(s)
####################

# Public route table
resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.vpc_eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = var.public_rt_tags
}

# Private Route Table
resource "aws_route_table" "rt_private" {
  vpc_id = aws_vpc.vpc_eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = var.private_rt_tags
}

# Associate the route table to each subnets
resource "aws_route_table_association" "rt-us-east-1a-private" {
  subnet_id      = aws_subnet.us-east-1a-private.id
  route_table_id = aws_route_table.rt_private.id
}

resource "aws_route_table_association" "rt-us-east-1b-private" {
  subnet_id      = aws_subnet.us-east-1b-private.id
  route_table_id = aws_route_table.rt_private.id
}

resource "aws_route_table_association" "rt-us-east-1a-public" {
  subnet_id      = aws_subnet.us-east-1a-public.id
  route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table_association" "rt-us-east-1b-public" {
  subnet_id      = aws_subnet.us-east-1b-public.id
  route_table_id = aws_route_table.rt_public.id
}
