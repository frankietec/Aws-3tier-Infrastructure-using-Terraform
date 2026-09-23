# Global / Project Settings

variable "aws_region" {
  description = "AWS region where all resources will be deployed"
  type        = string
}

variable "project_name" {
  description = "Name of the project used for tagging and naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "kubernetes_host" {
  description = "EKS API server endpoint used for Kubernetes and Helm providers. Provide only in the post-cluster phase."
  type        = string
  default     = ""
}

variable "kubernetes_cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate for the Kubernetes provider. Provide only in the post-cluster phase."
  type        = string
  default     = ""
}

variable "kubernetes_token" {
  description = "Bearer token for the Kubernetes provider. Provide only in the post-cluster phase."
  type        = string
  default     = ""
  sensitive   = true
}

############################################
# VPC Variables
############################################
variable "vpc_cidr" {
  description = "CIDR block for the entire VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDRs for EKS nodes"
  type        = list(string)
}

variable "infra_subnets" {
  description = "List of infrastructure subnet CIDRs for EKS control plane"
  type        = list(string)
}

############################################
# EKS Cluster Settings
############################################
variable "eks_node_groups" {
  description = "Node group configuration"
  type        = map(any)
}

############################################
# RDS Database Settings
############################################
variable "rds_instance_type" {
  description = "Instance class for the RDS instance"
  type        = string
}

variable "rds_allocated_storage" {
  description = "Storage size in GB"
  type        = number
}

variable "rds_dbname" {
  description = "Name of the database"
  type        = string
}

variable "rds_username" {
  description = "Master username for RDS"
  type        = string
}

variable "rds_password" {
  description = "Master password for RDS (sensitive)"
  type        = string
  sensitive   = true
}

variable "rds_port" {
  description = "Port number for RDS connectivity"
  type        = number
  default     = 5432
}

############################################
# Route53 & Namecheap Variables
############################################
variable "namecheap_domain" {
  description = "Domain name registered on Namecheap"
  type        = string
}
