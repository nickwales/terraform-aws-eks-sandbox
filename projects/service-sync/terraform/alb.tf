resource "aws_alb" "application_load_balancer" {
  name               = "consul-demo"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb.id]

  tags = {
    Name        = "consul-demo"

  }
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "frontend"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "10"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/health"
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "frontend"
  }
}

resource "aws_lb_listener" "consul_ui" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "8500"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.consul_ui.arn
  }
}

resource "aws_lb_target_group" "consul_ui" {
  name        = "consul-ui"
  port        = 8500
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "10"
    matcher             = "200"
    protocol            = "HTTP"
    timeout             = "3"
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "consul-ui"
  }
}

# resource "aws_lb_target_group_attachment" "test" {
#   target_group_arn = aws_lb_target_group.target_group.arn
#   target_id        = aws_ecs_cluster.consul-aws.
#   port             = 80
# }

resource "aws_security_group" "load_balancer_security_group" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name        = "sg"
  }
}