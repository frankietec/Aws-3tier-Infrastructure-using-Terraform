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
  count    = var.deploy_kubernetes_resources ? 1 : 0
  provider = kubernetes.post_eks # use the EKS provider alias
  metadata {
    name      = "nginx-ingress-${var.environment}-ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.nginx_ingress] # ensure Helm release is installed
}

# Get the regional hosted zone ID required for an ELB alias record.
data "aws_lb_hosted_zone_id" "nginx_ingress" {
  load_balancer_type = "application"
}

# Route53 record for the root domain
resource "aws_route53_record" "root" {
  count   = var.deploy_kubernetes_resources ? 1 : 0
  zone_id = aws_route53_zone.r53_zone.zone_id
  name    = var.namecheap_domain
  type    = "A"

  alias {
    name                   = data.kubernetes_service.nginx_ingress[0].status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb_hosted_zone_id.nginx_ingress.id
    evaluate_target_health = true
  }

  depends_on = [data.kubernetes_service.nginx_ingress]
}

# Route53 record for "api" subdomain
resource "aws_route53_record" "api" {
  count   = var.deploy_kubernetes_resources ? 1 : 0
  zone_id = aws_route53_zone.r53_zone.zone_id
  name    = "api.${var.namecheap_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [data.kubernetes_service.nginx_ingress[0].status[0].load_balancer[0].ingress[0].hostname]

  depends_on = [data.kubernetes_service.nginx_ingress]
}

# Route53 record for "argocd" subdomain
resource "aws_route53_record" "argocd" {
  count   = var.deploy_kubernetes_resources ? 1 : 0
  zone_id = aws_route53_zone.r53_zone.zone_id
  name    = "argocd.${var.namecheap_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [data.kubernetes_service.nginx_ingress[0].status[0].load_balancer[0].ingress[0].hostname]

  depends_on = [data.kubernetes_service.nginx_ingress]
}

# Route53 record for Grafana, which is served by the shared NGINX ingress LB.
resource "aws_route53_record" "grafana" {
  count   = var.deploy_kubernetes_resources ? 1 : 0
  zone_id = aws_route53_zone.r53_zone.zone_id
  name    = "grafana.${var.namecheap_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [data.kubernetes_service.nginx_ingress[0].status[0].load_balancer[0].ingress[0].hostname]

  depends_on = [
    data.kubernetes_service.nginx_ingress,
    helm_release.kube_prometheus_stack,
  ]
}

moved {
  from = aws_route53_record.bank
  to   = aws_route53_record.root
}

moved {
  from = aws_route53_record.bankapi
  to   = aws_route53_record.api
}
