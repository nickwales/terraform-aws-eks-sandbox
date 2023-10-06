resource "aws_security_group" "ecs" {
  name   = "${var.name}-example-client-app-alb"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Access to example client application."
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "#{var.name}-service-sync"
  }
}

resource "aws_security_group_rule" "ecs" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = data.aws_security_group.vpc_default.id
}

resource "aws_security_group" "route53_endpoints" {
  name_prefix = var.name
  description = "Route53 Endpoint"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "All access" # needs tightening but idk what traffic is coming in yet
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]    
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = module.vpc.private_subnets_cidr_blocks
    ipv6_cidr_blocks = ["::/0"]
  }
}


resource "aws_security_group" "alb" {
  name   = "${var.name}-service-sync-alb"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Remove access to service sync demo"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-service-sync-alb"
  }
}

resource "aws_security_group_rule" "alb-consul" {
  type              = "ingress"
  from_port         = 8500
  to_port           = 8500
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "apps" {
  name   = "${var.name}-service-sync-apps"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Access to example client application."
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-service-sync-apps"
  }
}

# resource "aws_security_group_rule" "ecs" {
#   type                     = "ingress"
#   from_port                = 0
#   to_port                  = 65535
#   protocol                 = "all"
#   source_security_group_id = aws_security_group.ecs.id
#   security_group_id        = data.aws_security_group.vpc_default.id
# }

