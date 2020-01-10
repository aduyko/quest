############
# Security Groups - Primary VPC
############

resource "aws_security_group" "elb_public_web" {
  name = "elb_public_web"
  description = "Inbound public web access intended for load balancers"
  vpc_id = aws_vpc.main.id

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

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name = "public_web"
    Service = "ECS"
    Environment = "test"
  }
}

resource "aws_security_group" "ec2_ecs_access" {
  name = "ecs_container_elb_access"
  description = "Allow load balancers to access ECS containers running on EC2"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 32768 # bottom of dynamic ECS port range
    to_port = 65535
    protocol = "tcp"
    security_groups = [
      aws_security_group.elb_public_web.id
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name = "ecs_access"
    Service = "ECS"
    Environment = "test"
  }
}