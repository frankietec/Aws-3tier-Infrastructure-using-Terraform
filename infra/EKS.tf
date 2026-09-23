module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  # Cluster identity
  cluster_name                   = "${var.project_name}-${var.environment}-cluster"
  cluster_version                = "1.35"
  cluster_endpoint_public_access = true
  enable_irsa                    = true

  # Networking
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets # worker node subnets
  control_plane_subnet_ids = module.vpc.intra_subnets   # control plane/infra subnets

  # Security Group Rules: Allow all node-to-node traffic for CNI pod networking
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Allow all node to node traffic across all ports"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  # Explicitly manage core addons
  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  # Node groups defined by variable
  eks_managed_node_groups = var.eks_node_groups

  tags = {
    Project = var.project_name
    Env     = var.environment
  }
}