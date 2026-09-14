# Useful outputs for post-deploy

# EKS
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  description = "IAM OIDC provider ARN used by IRSA"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_issuer_url" {
  description = "EKS OIDC issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}

# RDS
output "rds_endpoint" {
  description = "RDS endpoint for connecting applications"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.postgres.port
}

output "rds_secret_name" {
  description = "Kubernetes secret name containing RDS credentials"
  value       = kubernetes_secret.rds_credentials.metadata[0].name
}

# IRSA
output "irsa_role_arn" {
  description = "IAM role ARN used by the rds-access ServiceAccount"
  value       = aws_iam_role.rds_pod_role.arn
}

output "rds_serviceaccount_name" {
  description = "ServiceAccount name in Kubernetes for RDS access"
  value       = kubernetes_service_account.rds_access.metadata[0].name
}

# Ingress / Cert-manager
output "nginx_ingress_lb" {
  description = "Status of NGINX ingress helm release (use kubectl to inspect service)"
  value       = helm_release.nginx_ingress.status
}

output "cert_manager_status" {
  description = "Status of cert-manager helm release"
  value       = helm_release.cert_manager.status
}

# DNS
output "route53_nameservers" {
  description = "Route53 hosted zone nameservers (use these if necessary)"
  value       = aws_route53_zone.r53_zone.name_servers
}

# output "namecheap_nameservers" {
#   description = "Nameservers returned from Namecheap after update"
#   value       = namecheap_domain_dns.update_ns.nameservers
# }


# ECR
output "frontend_ecr_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "backend_ecr_url" {
  value = aws_ecr_repository.backend.repository_url
}

#Check whether cluster-issuer is ready



# R53 Records
output "root_domain_full_record" {
  value       = aws_route53_record.root
  description = "Full Route53 record object for the root domain"
}
