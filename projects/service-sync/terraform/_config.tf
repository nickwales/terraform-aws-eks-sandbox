terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }

  #required_version = "~> 1.2.0"
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks_cluster_primary.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster_primary.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }  
}


provider "helm" {
  kubernetes {
    host                   = module.eks_cluster_primary.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster_primary.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}