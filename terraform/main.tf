provider "aws" {
  profile = "default"
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "main"
 }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "main"
  }
}

resource "aws_default_route_table" "main" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "rearc_nodejs" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "192.168.0.0/20" # This creates ~4000 ips for our subnet

  tags = {
    Name = "rearc_nodejs"
    Service = "nodejs"
    Company = "rearc"
  }
}

resource "aws_security_group" "rearc_nodejs" {
  name = "rearc_nodejs_public"
  description = "Rearc NodeJS app inbound public web access"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rearc_nodejs"
    Service = "nodejs"
    Company = "rearc"
  }
}
