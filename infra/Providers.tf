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

# These data sources are still required for generated kubeconfig and other EKS-aware resources.
# They are not used in provider configuration, which avoids the Terraform cycle.
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name

  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name

  depends_on = [module.eks]
}

# Use the local kubeconfig for the EKS cluster instead of deriving the provider
# endpoint from module.eks. This avoids a circular dependency between the EKS
# module's aws-auth resources and the Kubernetes provider.
provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

# Aliased Kubernetes Provider for post-EKS resources.
provider "kubernetes" {
  alias       = "post_eks"
  config_path = pathexpand("~/.kube/config")
}

# Helm Provider using the same kubeconfig context.
provider "helm" {
  kubernetes = {
    config_path = pathexpand("~/.kube/config")
  }
}