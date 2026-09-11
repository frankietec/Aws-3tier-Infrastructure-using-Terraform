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
  }

  # namecheap = {
  #   source  = "namecheap/namecheap"
  # }
}



provider "aws" {
  region = var.aws_region
}


# namecheap providers
# provider "namecheap" {
#   user_name = var.namecheap_username
#   api_key   = var.namecheap_api_key
#   client_ip = var.namecheap_client_ip
#   sandbox   = false
# }


# EKS data sources
# These fetch: - API endpoint - CA certificate - Authentication token

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





# kubernetes provider
# Kubernetes provider for post-EKS resources
# Kubernetes provider alias for post-EKS resources
provider "kubernetes" {
  alias                  = "post_eks"
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}


# Helm provider using the aliased Kubernetes provider
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

