output "region" {
  value = var.region
}

output "cluster_name" {
  value = module.eks_cluster_primary.name
}

output "load_balancer" {
  value = aws_alb.application_load_balancer.dns_name
}