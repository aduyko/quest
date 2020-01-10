############
# Rearc Quest App Supporting Infrastructure
# Includes ECS Cluster an Service setup and EC2 Autoscaling
############

resource "aws_ecs_cluster" "rearc_quest" {
  name = "rearc_quest"
}

############
# EC2 Autoscaling
############

resource "aws_launch_configuration" "rearc_quest_ecs_lc" {
  name_prefix = "rearc_quest_ecs"

  image_id = var.ecs_optimized_ami
  instance_type = var.ec2_rearc_quest_instance_type
  security_groups = [aws_security_group.ec2_ecs_access.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_asg_instance_profile.id
  associate_public_ip_address = true

  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.rearc_quest.name} >> /etc/ecs/ecs.config
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "rearc_quest_ecs_asg" {
  name = "main_ecs_asg"
  vpc_zone_identifier = [aws_subnet.rearc_quest_a.id, aws_subnet.rearc_quest_b.id, aws_subnet.rearc_quest_c.id]
  min_size = var.asg_rearc_quest_min_size
  max_size = var.asg_rearc_quest_max_size
  desired_capacity = var.asg_rearc_quest_desired_capacity
  launch_configuration = aws_launch_configuration.rearc_quest_ecs_lc.name
  health_check_grace_period = 120
  default_cooldown = 30
  termination_policies = ["OldestInstance"]

  tag {
    key = "Name"
    value = "ECS-demo"
    propagate_at_launch = true
  }
}

############
# ECS Service and Task Definitions
############

resource "aws_ecs_task_definition" "rearc_quest" {
  family = "rearc_quest"
  container_definitions = file("task-definitions/rearc-quest.json")
}

resource "aws_ecs_service" "rearc_quest" {
  name = "rearc_quest"
  cluster = aws_ecs_cluster.rearc_quest.id
  task_definition = aws_ecs_task_definition.rearc_quest.id
  desired_count = 1
  iam_role = aws_iam_role.ecs_service_role.arn

  load_balancer {
    target_group_arn = aws_alb_target_group.main_ecs_target_group.id
    container_name = "rearc_quest"
    container_port = "3000"
  }
}
