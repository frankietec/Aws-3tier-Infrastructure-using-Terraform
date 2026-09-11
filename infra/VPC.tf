# VPC: creates networking used by EKS, RDS and other infra.
#
# This uses the terraform-aws-modules/vpc/aws module.
# All CIDRs, AZs and subnet lists are provided via variables.


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  # Naming and CIDR
  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  # Availability zones and subnets
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  intra_subnets   = var.infra_subnets

  # NAT + DNS
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Kubernetes helpful tags for ELB scheduling
  public_subnet_tags  = { "kubernetes.io/role/elb" = 1 }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 }

  tags = {
    Project = var.project_name
    Env     = var.environment
  }
}
