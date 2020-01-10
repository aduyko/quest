############
# Web-accessible ALB
############

resource "aws_alb" "main_ecs_alb" {
  name = "prod-public-ecs-web"
  security_groups = [aws_security_group.elb_public_web.id]
  subnets = [aws_subnet.rearc_quest_a.id, aws_subnet.rearc_quest_b.id, aws_subnet.rearc_quest_c.id]
}

output "ecs_alb_dns" {
  value = aws_alb.main_ecs_alb.dns_name
}

############
# Primary target group (populated by ECS)
############

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

############
# SSL Certificate (self signed)
############

resource "aws_iam_server_certificate" "rearc_quest_cert" {
  name = "rearc_quest_cert"
  certificate_body = file("certs/quest-rearc-public.pem")
  private_key = file("certs/quest-rearc-key.pem")
}

############
# Public Web Listeners for Web-accessible ALB (HTTP, HTTPS)
############

resource "aws_alb_listener" "main_ecs_alb_listener" {
  load_balancer_arn = aws_alb.main_ecs_alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.main_ecs_target_group.arn
    type = "forward"
  }
}

resource "aws_alb_listener" "main_ecs_alb_listener_ssl" {
  load_balancer_arn = aws_alb.main_ecs_alb.arn
  port = "443"
  protocol = "HTTPS"
  ssl_policy = var.alb_ssl_policy
  certificate_arn = aws_iam_server_certificate.rearc_quest_cert.arn

  default_action {
    target_group_arn = aws_alb_target_group.main_ecs_target_group.arn
    type = "forward"
  }
}
