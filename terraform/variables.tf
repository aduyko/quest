variable "aws_region" {
  type = "string"
  default = "us-east-1"
}

variable "ecs_optimized_ami" {
  type = "string"
  default = "ami-00afc256a955c31b5"
}

variable "ec2_rearc_quest_instance_type" {
  type = "string"
  default = "t3.small"
}

variable "asg_rearc_quest_min_size" {
  type = "string"
  default = "1"
}

variable "asg_rearc_quest_max_size" {
  type = "string"
  default = "4"
}

variable "asg_rearc_quest_desired_capacity" {
  type = "string"
  default = "1"
}

variable "alb_ssl_policy" {
  type = "string"
  default = "ELBSecurityPolicy-2016-08"
}