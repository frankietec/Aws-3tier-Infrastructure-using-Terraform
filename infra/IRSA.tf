# IRSA: IAM Role for Service Account (pods -> RDS)

# ----- IRSA TRUST POLICY -----
data "aws_iam_policy_document" "irsa_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(trim(module.eks.oidc_provider, "/"), "https://", "")}:sub"
      values   = ["system:serviceaccount:default:rds-access"]
    }
  }
}


# IAM Role for pods
resource "aws_iam_role" "rds_pod_role" {
  name               = "rds-pod-role-${var.project_name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role_policy.json
}

# IAM Policy
resource "aws_iam_policy" "rds_access" {
  name = "RDSAccessPolicy-${var.project_name}-${var.environment}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds-db:connect"
        ]
        Resource = [aws_db_instance.postgres.arn] # least privilege
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "attach_rds_policy" {
  role       = aws_iam_role.rds_pod_role.name
  policy_arn = aws_iam_policy.rds_access.arn
}

########################################################
# Kubernetes ServiceAccount (IRSA)
########################################################

resource "kubernetes_service_account" "rds_access" {
  count    = var.deploy_kubernetes_resources ? 1 : 0
  provider = kubernetes.post_eks # use alias
  metadata {
    name      = "rds-access"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.rds_pod_role.arn
    }
  }
  depends_on = [module.eks]
}

########################################################
# Kubernetes Secret with RDS credentials
########################################################

resource "kubernetes_secret" "rds_credentials" {
  count    = var.deploy_kubernetes_resources ? 1 : 0
  provider = kubernetes.post_eks # use alias
  metadata {
    name      = "rds-credentials"
    namespace = "default"
  }

  data = {
    username = base64encode(var.rds_username)
    password = base64encode(var.rds_password)
    host     = base64encode(aws_db_instance.postgres.endpoint)
    port     = base64encode(tostring(aws_db_instance.postgres.port))
    dbname   = base64encode(var.rds_dbname)
  }

  type       = "Opaque"
  depends_on = [module.eks, aws_db_instance.postgres]
}
