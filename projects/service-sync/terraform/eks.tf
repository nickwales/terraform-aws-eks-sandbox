module "eks_cluster_primary" {
    source = "../../../modules/eks"
    name   = var.cluster_name
    region = var.region
    
    vpc_id          = module.vpc.vpc_id
    public_subnets  = module.vpc.public_subnets
    private_subnets = module.vpc.private_subnets
}

resource "helm_release" "lb" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    module.eks_cluster_primary.kubernetes_service_account
  ]

#   set {
#     name  = "region"
#     value = var.region
#   }

#   set {
#     name  = "vpcId"
#     value = module.vpc.default_vpc_id
#   }

#   set {
#     name  = "image.repository"
#     value = "public.ecr.aws/eks/aws-load-balancer-controller:v2.5.4"
#   }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

   set {
     name  = "clusterName"
     value = var.cluster_name
   }
}

resource "kubernetes_namespace" "consul" {
  metadata {
    annotations = {
      name = "consul"
    }

    labels = {
      mylabel = "consul"
    }

    name = "consul"
  }
}

resource "kubernetes_secret" "consul-agent-ca" {
  metadata {
    name      = "consul-agent-ca"
    namespace = "consul"
  }

  data = {
    "tls.crt" = "${file("${path.module}/../certs/consul-agent-ca.pem")}",
    "terraform" = "true"
  }
}

resource "kubernetes_secret" "consul-agent-ca-key" {
  metadata {
    name      = "consul-agent-ca-key"
    namespace = "consul"
  }

  data = {
    "tls.crt" = "${file("${path.module}/../certs/consul-agent-ca-key.pem")}",
    "terraform" = "true"
  }
}

resource "kubernetes_secret" "consul_token" {
  metadata {
    name      = "acl-token"
    namespace = "consul"
  }

  data = {
    "key" = var.consul_token
  }
}

resource "helm_release" "consul" {
  name       = "consul"
  namespace  = "consul"

  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"

  values = [
    "${file("${path.module}/../helm/external_server.yaml")}"
  ]  
}

# resource "helm_release" "nginx-ingress" {
#   name       = "nginx-ingress"

#   repository = "oci://ghcr.io/nginxinc/charts/nginx-ingress"
#   chart      = "nginx-ingress"
#   version    = "0.18.0"

#   values = [
#     "${file("${path.module}/../helm/external_server.yaml")}"
#   ]  
# }

# helm install nginx-ingress oci://ghcr.io/nginxinc/charts/nginx-ingress --version 0.18.0
