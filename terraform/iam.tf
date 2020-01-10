############
# EC2 instance role for use with ECS
############

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

############
# ECS service role
############

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
