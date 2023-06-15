
module "eks_cluster_primary" {
    source = "../../modules/eks"
    name   = "service-sync-demo"

}

output "cluster_name" {
    value = module.eks_cluster_primary.name
}

output "region" {
    value = module.eks_cluster_primary.region
}