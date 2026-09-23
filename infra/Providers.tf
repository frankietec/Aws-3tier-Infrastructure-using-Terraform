terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }

    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# EKS data sources used for kubeconfig generation and cluster-aware resources.
# They are kept separate from the provider configuration to avoid a cycle during validation.
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name

  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name

  depends_on = [module.eks]
}

# Kubernetes and Helm credentials are intentionally injected via variables.
# Using null defaults keeps the Terraform graph acyclic during validate and plan.
provider "kubernetes" {
  host                   = var.kubernetes_host != "" ? var.kubernetes_host : null
  cluster_ca_certificate = var.kubernetes_cluster_ca_certificate != "" ? var.kubernetes_cluster_ca_certificate : null
  token                  = var.kubernetes_token != "" ? var.kubernetes_token : null
}

provider "kubernetes" {
  alias                  = "post_eks"
  host                   = var.kubernetes_host != "" ? var.kubernetes_host : null
  cluster_ca_certificate = var.kubernetes_cluster_ca_certificate != "" ? var.kubernetes_cluster_ca_certificate : null
  token                  = var.kubernetes_token != "" ? var.kubernetes_token : null
}

provider "helm" {
  kubernetes = {
    host                   = var.kubernetes_host != "" ? var.kubernetes_host : null
    cluster_ca_certificate = var.kubernetes_cluster_ca_certificate != "" ? var.kubernetes_cluster_ca_certificate : null
    token                  = var.kubernetes_token != "" ? var.kubernetes_token : null
  }
}