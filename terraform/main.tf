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
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

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

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "rearc_quest_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "192.168.0.0/22" # This creates ~4000 ips for our subnet
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "rearc_quest"
    Service = "quest"
    Environment = "nodejs"
    Company = "rearc"
  }
}

resource "aws_subnet" "rearc_quest_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "192.168.4.0/22" # This creates ~1000 ips for our subnet
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "rearc_quest"
    Service = "quest"
    Environment = "nodejs"
    Company = "rearc"
  }
}

resource "aws_subnet" "rearc_quest_c" {
  vpc_id = aws_vpc.main.id
  cidr_block = "192.168.8.0/22" # This creates ~4000 ips for our subnet
  availability_zone = data.aws_availability_zones.available.names[2]

  tags = {
    Name = "rearc_quest"
    Service = "quest"
    Environment = "nodejs"
    Company = "rearc"
  }
}

resource "aws_security_group" "elb_public_web" {
  name = "elb_public_web"
  description = "Inbound public web access intended for load balancers"
  #description = "Rearc NodeJS app inbound public web access"
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
    Name = "rearc_quest"
    Service = "quest"
    Environment = "nodejs"
    Company = "rearc"
  }
}

resource "aws_security_group" "ec2_ecs_access" {
  name = "ecs_container_elb_access"
  description = "Access ecs containers from public web load balancer"
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
    Name = "rearc_quest"
    Service = "quest"
    Environment = "nodejs"
    Company = "rearc"
  }
}
  #description = "Rearc NodeJS app inbound public web access"

# Create our ECS and EC2 IAM roles

data "aws_iam_policy_document" "ec2_asg_instance" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_asg_service_role" {
  name = "ec2_asg_service_role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_asg_instance.json
}

resource "aws_iam_role_policy_attachment" "ec2_asg_role_attachment" {
  role = aws_iam_role.ec2_asg_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2_asg_instance_profile" {
  name = "ec2_asg_instance_profile"
  role = aws_iam_role.ec2_asg_service_role.name
}

data "aws_iam_policy_document" "ecs_service" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service_role" {
  name = "ecs_service_role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_service.json
}

resource "aws_iam_role_policy_attachment" "ecs_service_role_attachment" {
  role = aws_iam_role.ecs_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

# Set up ALB

resource "aws_alb" "main_ecs_alb" {
  name = "prod-public-ecs-web"
  security_groups = [aws_security_group.elb_public_web.id]
  subnets = [aws_subnet.rearc_quest_a.id, aws_subnet.rearc_quest_b.id, aws_subnet.rearc_quest_c.id]
}

output "ecs_alb_dns" {
  value = aws_alb.main_ecs_alb.dns_name
}

resource "aws_alb_target_group" "main_ecs_target_group" {
  name = "prod-public-ecs-target-group"
  port = "80"
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id

  health_check {
    path = "/"
    timeout = 15
    interval = 30
    matcher = "200"
  }

  depends_on = [aws_alb.main_ecs_alb]
}

resource "aws_alb_listener" "main_ecs_alb_listener" {
  load_balancer_arn = aws_alb.main_ecs_alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.main_ecs_target_group.arn
    type = "forward"
  }
}

resource "aws_iam_server_certificate" "rearc_quest_cert" {
  name = "rearc_quest_cert"
  certificate_body = file("certs/quest-rearc-public.pem")
  private_key = file("certs/quest-rearc-key.pem")
}

resource "aws_alb_listener" "main_ecs_alb_listener_ssl" {
  load_balancer_arn = aws_alb.main_ecs_alb.arn
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_iam_server_certificate.rearc_quest_cert.arn

  default_action {
    target_group_arn = aws_alb_target_group.main_ecs_target_group.arn
    type = "forward"
  }
}

# Autoscaling Group

resource "aws_ecs_cluster" "main" {
  name = "main"
}

resource "aws_launch_configuration" "main_ecs_lc" {
  name_prefix = "main_ecs"

  image_id = "ami-00afc256a955c31b5"
  instance_type = "t3.small"
  security_groups = [aws_security_group.ec2_ecs_access.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_asg_instance_profile.id
  associate_public_ip_address = true

  user_data = <<EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main_ecs_asg" {
  name = "main_ecs_asg"
  vpc_zone_identifier = [aws_subnet.rearc_quest_a.id, aws_subnet.rearc_quest_b.id, aws_subnet.rearc_quest_c.id]
  min_size = "1"
  max_size = "4"
  desired_capacity = "1"
  launch_configuration = aws_launch_configuration.main_ecs_lc.name
  health_check_grace_period = 120
  default_cooldown = 30
  termination_policies = ["OldestInstance"]

  tag {
    key = "Name"
    value = "ECS-demo"
    propagate_at_launch = true
  }
}

# ecs service and task creation

resource "aws_ecs_task_definition" "rearc_quest" {
  family = "rearc_quest"
  container_definitions = file("task-definitions/rearc-quest.json")
}

resource "aws_ecs_service" "rearc_quest" {
  name = "rearc_quest"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.rearc_quest.id
  desired_count = 1
  iam_role = aws_iam_role.ecs_service_role.arn

  load_balancer {
    target_group_arn = aws_alb_target_group.main_ecs_target_group.id
    container_name = "rearc_quest"
    container_port = "3000"
  }
}
