resource "aws_ecs_cluster" "consul-aws" {
  name = "consul-aws"
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend"
  cluster         = aws_ecs_cluster.consul-aws.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 2
  launch_type     = "FARGATE"
 # iam_role        = aws_iam_role.foo.arn
 # depends_on      = [aws_iam_role_policy.foo]

  network_configuration {
    subnets = module.vpc.public_subnets
    assign_public_ip = true
    security_groups = [aws_security_group.apps.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 9090
  }

  service_registries {
    registry_arn = aws_service_discovery_service.frontend.arn
  }
}


resource "aws_ecs_task_definition" "frontend" {
  family = "service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  #execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  #task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  cpu                      = 1024
  memory                   = 2048

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "docker.mirror.hashicorp.services/nicholasjackson/fake-service:v0.25.2"
      cpu       = 100
      memory    = 128
      essential = true
      environment = [
        {"name":"LISTEN_ADDR", "value": "0.0.0.0:9090"}, 
        {"name": "NAME", "value": "frontend - running on ECS"},
        {"name": "MESSAGE", "value": "frontend running on ECS"},
        {"name": "UPSTREAM_URIS", "value": "http://middleware.service.consul:9090,http://images.service.consul:9090"},
      ]

      portMappings = [
        {
          containerPort = 9090
          hostPort      = 9090
        }
      ]
    }
  ])
}



### images

resource "aws_ecs_service" "images" {
  name            = "images"
  cluster         = aws_ecs_cluster.consul-aws.id
  task_definition = aws_ecs_task_definition.images.arn
  desired_count   = 3
  launch_type     = "FARGATE"
 # iam_role        = aws_iam_role.foo.arn
 # depends_on      = [aws_iam_role_policy.foo]

  network_configuration {
    subnets = module.vpc.public_subnets
    assign_public_ip = true
    security_groups = [aws_security_group.apps.id]
  }

  # load_balancer {
  #   target_group_arn = aws_lb_target_group.images.arn
  #   container_name   = "frontend"
  #   container_port   = 9090
  # }

  service_registries {
    registry_arn = aws_service_discovery_service.images.arn
  }
}


resource "aws_ecs_task_definition" "images" {
  family = "service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  #execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  #task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  cpu                      = 1024
  memory                   = 2048

  container_definitions = jsonencode([
    {
      name      = "images"
      image     = "docker.mirror.hashicorp.services/nicholasjackson/fake-service:v0.25.2"
      cpu       = 100
      memory    = 128
      essential = true
      environment = [
        {"name":"LISTEN_ADDR", "value": "0.0.0.0:9090"}, 
        {"name": "NAME", "value": "Images Service on ECS"},
        {"name": "MESSAGE", "value": "Images Service on ECS"},
      ]

      portMappings = [
        {
          containerPort = 9090
          hostPort      = 9090
        }
      ]
    }
  ])
}
