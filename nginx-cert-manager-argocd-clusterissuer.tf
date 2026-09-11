# -------------------------
# NGINX Ingress via Helm
# -------------------------
resource "helm_release" "nginx_ingress" {
  provider         = helm
  name             = "nginx-ingress-${var.environment}"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.12.0"
  namespace        = "ingress-nginx"
  create_namespace = true
  timeout          = 600
  wait             = true # Wait for all resources to be ready

  values = [
    file("nginx-values.yaml")
  ]

  depends_on = [module.eks]
}

# -------------------------
# Wait for NGINX webhook secret and patch job
# -------------------------
resource "null_resource" "wait_for_nginx_webhook" {
  depends_on = [helm_release.nginx_ingress]

  provisioner "local-exec" {
    command = <<EOT
echo "Waiting for NGINX admission webhook secret..."
until kubectl get secret ingress-nginx-admission -n ingress-nginx &> /dev/null; do
  sleep 5
done

echo "Waiting for NGINX admission webhook patch job to complete..."
while [[ $(kubectl get job ingress-nginx-admission-patch -n ingress-nginx -o jsonpath='{.status.succeeded}') != "1" ]]; do
  sleep 5
done

echo "NGINX webhook ready!"
EOT
  }
}

# -------------------------
# Cert-Manager via Helm
# -------------------------
resource "helm_release" "cert_manager" {
  provider         = helm
  name             = "cert-manager-${var.environment}"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.14.5"
  namespace        = "cert-manager"
  create_namespace = true
  timeout          = 600
  wait             = true

  values = [
    file("cert-manager-values.yaml")
  ]

  depends_on = [module.eks]
}

# -------------------------
# Kubeconfig for local-exec
# -------------------------
resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig"

  depends_on = [module.eks]

  content = <<EOF
apiVersion: v1
kind: Config
clusters:
- name: eks
  cluster:
    server: ${data.aws_eks_cluster.cluster.endpoint}
    certificate-authority-data: ${data.aws_eks_cluster.cluster.certificate_authority[0].data}
contexts:
- name: eks
  context:
    cluster: eks
    user: eks
current-context: eks
users:
- name: eks
  user:
    token: ${data.aws_eks_cluster_auth.cluster.token}
EOF
}

# -------------------------
# Apply ClusterIssuer
# -------------------------
resource "null_resource" "create_cluster_issuer" {
  depends_on = [
    helm_release.cert_manager,
    local_file.kubeconfig
  ]

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_file.kubeconfig.filename
    }

    command = "kubectl apply -f cluster-issuer.yaml"
  }
}

# -------------------------
# ArgoCD via Helm
# -------------------------
resource "helm_release" "argocd" {
  provider         = helm
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.51.6"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 600
  wait             = true

  values = [
    file("argocd-values.yaml")
  ]

  depends_on = [
    null_resource.wait_for_nginx_webhook,
    null_resource.create_cluster_issuer
  ]
}


# -------------------------
# Apply Argocd-ingress
# -------------------------
resource "null_resource" "apply_argocd_ingress" {
  depends_on = [
    helm_release.argocd,        # wait for ArgoCD to be installed
    helm_release.nginx_ingress, # optional, ensures ingress controller exists
    null_resource.create_cluster_issuer,
  ]

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_file.kubeconfig.filename
    }

    command = "kubectl apply -f ${path.module}/argocd-ingress.yaml"

  }
}
