output "region" {
  value = var.region
}

output "cluster_name" {
  value = module.eks_cluster_primary.name
}

output "consul_ui_addr" {
  value = "${aws_alb.application_load_balancer.dns_name}:8500"
}

output "application_addr" {
  value = "${aws_alb.application_load_balancer.dns_name}/ui"
}