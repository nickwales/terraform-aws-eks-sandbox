resource "aws_service_discovery_http_namespace" "dev" {
  name        = "development"
  description = "example"
}

resource "aws_service_discovery_service" "frontend" {
  name         = "frontend"
  namespace_id = aws_service_discovery_http_namespace.dev.id
}

resource "aws_service_discovery_service" "images" {
  name         = "images"
  namespace_id = aws_service_discovery_http_namespace.dev.id
  # health_check_config {
  #   resource_path = "/health"
  #   type          = "HTTP"
  # }
}