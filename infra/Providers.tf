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

# EKS data sources
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name

  depends_on = [
    module.eks
  ]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name

  depends_on = [
    module.eks
  ]
}

# Keep an aliased Kubernetes provider for resources that are created after the cluster exists.
# The default kubernetes provider is intentionally omitted to avoid a circular dependency with
# the terraform-aws-modules/eks module's aws-auth configmap management.
provider "kubernetes" {
  alias                  = "post_eks"
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Helm Provider using EKS credentials
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}