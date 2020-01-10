############
# Primary VPC
############

resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "main"
 }
}

############
# Internet gateway - Primary VPC
############

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

############
# Routing table - Primary VPC
############

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main"
  }
}

############
# Subnets - Primary VPC
# These are split across three availability zones
# with each subnet spanning approximately 1000 ips
# The only subnets for now are for the rearc quest ECS containers
############

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "rearc_quest_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "192.168.0.0/22"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "rearc_quest"
    Service = "quest"
    Environment = "test"
    Company = "rearc"
  }
}

resource "aws_subnet" "rearc_quest_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "192.168.4.0/22"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "rearc_quest"
    Service = "quest"
    Environment = "test"
    Company = "rearc"
  }
}

resource "aws_subnet" "rearc_quest_c" {
  vpc_id = aws_vpc.main.id
  cidr_block = "192.168.8.0/22"
  availability_zone = data.aws_availability_zones.available.names[2]

  tags = {
    Name = "rearc_quest"
    Service = "quest"
    Environment = "test"
    Company = "rearc"
  }
}
