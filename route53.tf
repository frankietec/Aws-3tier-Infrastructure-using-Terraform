# Route53 hosted zone and Namecheap sync
#
# - Creates a Route53 public hosted zone for the domain.
# - Updates the domain's nameservers at Namecheap to point to the Route53 nameservers.
# NOTE: Ensure the domain is registered at Namecheap and the Namecheap API user has
#       permissions to manage DNS.


# Create a Route53 hosted zone for the domain
resource "aws_route53_zone" "r53_zone" {
  name = var.namecheap_domain
  tags = {
    Project = var.project_name
    Env     = var.environment
  }
}

# # Update Namecheap DNS to use the Route53 nameservers
# resource "namecheap_domain_dns" "update_ns" {
#   domain      = var.namecheap_domain
#   nameservers = aws_route53_zone.example.name_servers
# }


# Fetch the NGINX Ingress LoadBalancer service
data "kubernetes_service" "nginx_ingress" {
  provider = kubernetes.post_eks # use the EKS provider alias
  metadata {
    name      = "nginx-ingress-${var.environment}-ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.nginx_ingress] # ensure Helm release is installed
}

# Route53 record for "bank" subdomain
resource "aws_route53_record" "bank" {
  zone_id = aws_route53_zone.r53_zone.zone_id
  name    = "bank.${var.namecheap_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].hostname]

  depends_on = [data.kubernetes_service.nginx_ingress]
}

# Route53 record for "bankapi" subdomain
resource "aws_route53_record" "bankapi" {
  zone_id = aws_route53_zone.r53_zone.zone_id
  name    = "bankapi.${var.namecheap_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].hostname]

  depends_on = [data.kubernetes_service.nginx_ingress]
}

# Route53 record for "argocd" subdomain
resource "aws_route53_record" "argocd" {
  zone_id = aws_route53_zone.r53_zone.zone_id
  name    = "argocd.${var.namecheap_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].hostname]

  depends_on = [data.kubernetes_service.nginx_ingress]
}
