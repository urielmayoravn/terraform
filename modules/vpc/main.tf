locals {
  all_ips             = "0.0.0.0/0"
  name_prefix         = "TF-TEST"
  public_route_table  = one(aws_route_table.public[*].id)
  private_route_table = one(aws_route_table.private[*].id)
  internet_gateway    = one(aws_internet_gateway.igw[*].id)
  elastic_ip          = one(aws_eip.nat_eip[*].id)
  nat_gateway         = one(aws_nat_gateway.nat[*].id)

}

resource "aws_vpc" "vpc" {
  cidr_block         = var.cidr_block
  enable_dns_support = true
  tags               = { "Name" = "${local.name_prefix}-VPC" }
}

resource "aws_subnet" "public" {
  for_each                = { for i, val in var.public_subnets : i => val }
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  tags                    = { "Name" = each.value.name != null ? each.value.name : "" }
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  for_each          = { for i, val in var.private_subnets : i => val }
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az
  tags              = { "Name" = each.value.name != null ? each.value.name : "" }
}

resource "aws_subnet" "private_db" {
  for_each          = { for i, val in var.db_subnets : i => val }
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az
  tags              = { "Name" = each.value.name != null ? each.value.name : "" }
}

resource "aws_internet_gateway" "igw" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  tags   = { "Name" = "${local.name_prefix}-IGW" }

}

resource "aws_route_table" "public" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = local.all_ips
    gateway_id = local.internet_gateway
  }
  tags = { "Name" = "${local.name_prefix}-PUBLIC-RT" }
}

resource "aws_route_table_association" "route_table_association" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = local.public_route_table
}

resource "aws_eip" "nat_eip" {
  count = length(var.private_subnets) > 0 && length(var.public_subnets) > 0 ? 1 : 0
  tags  = { "Name" = "${local.name_prefix}-NAT-EIP" }
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.private_subnets) > 0 && length(var.public_subnets) > 0 ? 1 : 0
  allocation_id = local.elastic_ip
  subnet_id     = values(aws_subnet.public)[0].id
  tags          = { "Name" = "${local.name_prefix}-NAT-GW" }

}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets) + length(var.db_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  tags   = { "Name" = "${local.name_prefix}-PRIVATE-RT" }

  route {
    cidr_block     = local.all_ips
    nat_gateway_id = local.nat_gateway
  }
}

resource "aws_route_table_association" "private_routing" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = local.private_route_table
}

resource "aws_route_table_association" "private_db_routing" {
  for_each       = aws_subnet.private_db
  subnet_id      = each.value.id
  route_table_id = local.private_route_table
}
