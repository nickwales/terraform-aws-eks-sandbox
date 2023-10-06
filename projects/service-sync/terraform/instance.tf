resource "aws_instance" "consul_server" {
#  count = 1

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  subnet_id     = module.vpc.private_subnets[0]

  vpc_security_group_ids = [aws_security_group.apps.id]
  iam_instance_profile = aws_iam_instance_profile.instance.name

  tags = {
    Terraform = "true"
    Environment = "dev"
    ttl = 72
    hc-internet-facing = "true"
    Name = "consul-aws"
    Owner = "nwales"
    Purpose = "Sandbox Testing"
    se_region = "AMER"
    Role = "hashistack-client"
  }

  user_data = templatefile("${path.module}/templates/userdata.sh.tftpl", {
    cloudmap_id = aws_service_discovery_http_namespace.dev.id,
    datacenter = "dc1", 
    consul_token = var.consul_token    
    # client_number     = count.index,
    # role              = "proxy",
    # consul_token      = var.consul_token,
    # consul_datacenter = var.consul_datacenter
  })
}

resource "aws_lb_target_group_attachment" "consul_ui" {
  target_group_arn = aws_lb_target_group.consul_ui.arn
  target_id        = aws_instance.consul_server.id
  port             = 8500
}