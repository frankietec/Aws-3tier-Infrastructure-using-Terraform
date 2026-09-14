# AWS Three-Tier Application Runbook

This repository is a learning monorepo for deploying a frontend, backend, and data tier on AWS with Terraform and Kubernetes.

## Repository layout

```text
infra/                 Terraform infrastructure and platform manifests
frontend/              React application and Dockerfile
backend/               Node.js/Express application and Dockerfile
app-manifests/         Kubernetes application, database, ingress, and TLS manifests
.github/workflows/     Infrastructure, frontend, and backend pipelines
```

## Architecture

Terraform provisions:

- A VPC with public, private, and intra subnets.
- An EKS 1.35 cluster with `c7i-flex.large` managed worker nodes.
- The AWS EBS CSI managed add-on, configured with IRSA and an encrypted `gp3` StorageClass.
- Amazon Linux 2023 worker AMIs with On-Demand capacity.
- An RDS PostgreSQL instance in private subnets.
- ECR repositories:
  - `dev-frontend`
  - `dev-backend`
- NGINX Ingress, cert-manager, and Argo CD through Helm. Argo CD is the
  deployment controller for the application manifests.
- kube-prometheus-stack through Helm, with persistent gp3 storage and Grafana
  exposed through NGINX Ingress.
- Route 53 records for `joybassey.online`.

The application ingress uses:

```text
https://joybassey.online       Frontend
https://api.joybassey.online   Backend
https://argocd.joybassey.online Argo CD
https://grafana.joybassey.online Grafana
```

## Prerequisites

Install and configure:

- AWS CLI
- Terraform >= 1.5
- kubectl
- Helm >= 3
- Node.js and npm
- Docker

The AWS identity used locally and by GitHub Actions needs permissions for EKS, EC2, RDS, ECR, Route 53, IAM, S3, and related services.

## Terraform state backend

Terraform state uses the S3 backend configured in [infra/backend.tf](./infra/backend.tf).

The bucket must exist before Terraform initialization:

```bash
aws s3api head-bucket \
  --bucket sam-osung-terraform-state-20260911 \
  --region us-east-1
```

The state bucket should have versioning and encryption enabled. Do not delete it while the environment is in use.

## Deploy infrastructure

From the repository root:

```bash
cd infra
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

The GitHub Actions equivalent is [infra-cicd.yaml](./.github/workflows/infra-cicd.yaml):

1. A push to `main` that changes `infra/**` runs format, validation, TFLint, tfsec, and plan.
2. The plan is uploaded as an artifact.
3. Use **Actions -> Deploy to AWS with Terraform -> Run workflow**.
4. Choose `apply` or `destroy`.

There is no environment reviewer gate. The workflow's manual action choice is the operational safeguard.

After EKS is created, configure kubectl:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name joybassey-app-dev-cluster
kubectl get nodes
aws eks describe-addon \
  --cluster-name joybassey-app-dev-cluster \
  --addon-name aws-ebs-csi-driver \
  --region us-east-1

terraform output eks_oidc_provider_arn
terraform output eks_oidc_issuer_url
```

Terraform creates the EBS CSI add-on after the cluster and its OIDC provider
are ready. The add-on uses the `AmazonEBSCSIDriverPolicy` through a dedicated
IRSA role; no `eksctl create addon` step is required. The `gp3` StorageClass
is created by Terraform and is used by the MySQL StatefulSet.

Terraform also installs the Prometheus community `kube-prometheus-stack` chart
in the `monitoring` namespace. Grafana uses the shared NGINX ingress and the
existing cert-manager `http-01-production` ClusterIssuer; Prometheus,
Alertmanager, and Grafana data are persisted on the encrypted `gp3`
StorageClass. Terraform generates the Grafana admin password and Helm stores
it in the `monitoring` namespace:

```bash
kubectl get secret prometheus-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 --decode
```

## Deploy the application with Argo CD

Terraform installs and configures Argo CD in the `argocd` namespace, including
the TLS-protected Argo CD Ingress at
`https://argocd.joybassey.online`. Application resources under
`app-manifests/` are intended to be delivered through Argo CD, not applied
individually with `kubectl`.

After Terraform has completed:

1. Open Argo CD at `https://argocd.joybassey.online`.
2. Create or update the Argo CD Application to use this repository as its
   source, with `app-manifests/` as the path and the target EKS cluster and
   namespace configured for the application.
3. Enable automated sync and pruning if that is the desired environment
   policy.
4. Sync the application from the Argo CD UI or CLI.

The application CI/CD workflows build and publish frontend and backend images.
The `update-manifest` workflow then updates the image references in
`app-manifests/frontend-deployment.yaml` and
`app-manifests/backend-deployment.yaml`. Argo CD detects those Git changes and
reconciles the workloads into the cluster.

For this learning environment, the backend manifest sets `CORS_ORIGINS=*` so
students can connect to the API from different frontend hosts. Restrict this
value to trusted frontend origins before using the deployment for production.

The MySQL migration is represented by a one-shot Job in the application
manifests. It waits for the `mysql` service, reads the password from
`mysql-secret`, reads the database name from `mysql-config`, and executes the
SQL in the migration ConfigMap. For a new schema migration, use a new Job name
such as `mysql-migration-v2`; completed Jobs do not automatically run again.

Use `kubectl` for read-only operational checks:

```bash
kubectl get pods
kubectl get job mysql-migration
kubectl logs job/mysql-migration
```

## Application CI/CD

The application pipelines are:

- [frontend-cicd.yaml](./.github/workflows/frontend-cicd.yaml)
- [backend-cicd.yaml](./.github/workflows/backend-cicd.yaml)

### Automatic build and release

A push to `frontend/**` or `backend/**` on `main` runs the matching pipeline:

1. Install dependencies with `npm ci`.
2. Run lint.
3. Run tests.
4. Build the Docker image.
5. Push it to ECR.
6. Create a GitHub Release using the same image tag.

Image and release tags are identical:

```text
frontend-<run-number>
backend-<run-number>
```

For example:

```text
323149985350.dkr.ecr.us-east-1.amazonaws.com/dev-frontend:frontend-42
323149985350.dkr.ecr.us-east-1.amazonaws.com/dev-backend:backend-43
```

### Manual rebuild

Use **Actions -> Frontend CI/CD** or **Backend CI/CD -> Run workflow**, then choose `build`.

This rebuilds and pushes an image even when no new application commit exists. It also creates a matching GitHub Release.

### Promote the latest release to Kubernetes

Run the matching workflow manually and choose `update-manifest`.

The workflow automatically finds the latest release for that application, updates the corresponding deployment manifest, commits it, and pushes it:

```text
app-manifests/frontend-deployment.yaml
app-manifests/backend-deployment.yaml
```

No image tag needs to be entered manually.

## Local application checks

Frontend:

```bash
cd frontend
npm ci
npm run lint -- --max-warnings=0
CI=true npm test -- --watchAll=false --runInBand
npm run build
```

Backend:

```bash
cd backend
npm ci
npm run lint
npm test
```

The backend test is a lightweight Node smoke test and does not require a live database.

## GitHub Actions configuration

Add these repository secrets under **Settings -> Secrets and variables -> Actions**:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

The workflows derive the ECR registry from the authenticated AWS account, so an `ECR_REPO` variable is not required.

Never commit:

```text
frontend/.env
backend/.env
app-manifests/secret.yaml
```

These files contain environment-specific values or credentials and are ignored by `.gitignore`. Use GitHub Secrets, Kubernetes Secrets, or an external secret manager for real environments.

## Troubleshooting

### Terraform backend does not exist

Create the configured S3 bucket before running `terraform init`, or update [infra/backend.tf](./infra/backend.tf) to an existing bucket.

### ECR login targets Docker Hub

The workflow must authenticate AWS first and derive an ECR repository from `aws sts get-caller-identity`. If it targets `registry-1.docker.io`, check AWS credentials and rerun the workflow.

### EKS node group AMI error

Confirm [infra/EKS.tf](./infra/EKS.tf) uses EKS 1.35 and [infra/terraform.tfvars](./infra/terraform.tfvars) contains:

```hcl
instance_types = ["c7i-flex.large"]
capacity_type  = "ON_DEMAND"
ami_type       = "AL2023_x86_64_STANDARD"
```

### Terraform destroy cannot delete ECR

The ECR resources use `force_delete = true` for this learning environment. Destroying them removes all images in the repositories. Do not use this setting for production without an explicit retention policy.

### Helm uninstall times out

Inspect the cluster and release:

```bash
helm list --all-namespaces
kubectl get pods --all-namespaces
kubectl get namespace cert-manager
```

If the EKS cluster is already gone, rerun Terraform destroy so Terraform can reconcile the remaining state.

## Cleanup

To destroy the learning environment, use the infrastructure workflow and choose `destroy`, or run:

```bash
cd infra
terraform destroy
```

This can delete EKS, RDS, ECR repositories and images, networking, DNS records, and supporting IAM resources. Confirm that the AWS account and state bucket are the intended ones before proceeding.
