# Kubernetes Tech Challenge — AWS + Helm + Argo CD + Terraform + GitHub Actions

This repository provides a complete reference implementation that:

- Provisions an **AWS EKS** cluster with **Terraform** (uses terraform-aws-modules/eks/aws)
- Packages and deploys a sample app using a **Helm** chart
- Uses **Ingress NGINX** as the reverse proxy (installed via Helm)
- Enables scaling via a **Horizontal Pod Autoscaler (HPA)**
- Uses **Argo CD** for GitOps and to watch the Helm chart (sync Helm chart from repo)
- Provides a **GitHub Actions** CI pipeline that builds a container image, pushes to **ECR**, updates the Helm values (image tag) and triggers Argo CD to sync

## What is included
- `app/` — simple Flask app + Dockerfile
- `charts/testapp/` — Helm chart for the app (deployment, service, hpa, ingress)
- `terraform/aws/` — Terraform code to provision VPC, EKS cluster, node groups (uses terraform-aws-modules)
- `.github/workflows/ci-cd.yml` — GitHub Actions workflow for CI/CD
- `argocd/` — Argo CD Application manifest pointing to `charts/testapp`
- `Makefile` — helper targets for local testing and Terraform commands

## Important notes (read before running)
- **Do not commit sensitive credentials.** Use GitHub Secrets for CI (AWS keys, ECR, Argo CD token, DockerHub if used).
- Terraform backend is configured to use an S3 bucket — replace `backend.tf` values with your own bucket and region.
- The ECR setup in CI expects the repository to exist or uses `aws ecr create-repository` in the workflow.
- The Terraform `eks` module version and AWS provider versions are pinned in `versions.tf`. Update to latest if needed.

## Quick flow (high-level)
1. Create Terraform backend S3 bucket and DynamoDB table for locking (or update `terraform/backend.tf`).
2. `terraform init && terraform apply` in `terraform/aws` to create EKS cluster and outputs.
3. Install `kubectl`, `helm`, and `aws` CLI locally; configure `aws` credentials.
4. Add `ingress-nginx` and `argocd` via Helm or use the provided manifests.
5. Use GitHub Actions on push to `main` to build/push image to ECR and update Helm values.
6. Argo CD will sync the chart from this repository and deploy the new image tag.

## Files of interest
- `terraform/aws/main.tf` — EKS provisioning
- `charts/testapp/` — Helm chart
- `.github/workflows/ci-cd.yml` — CI/CD
- `argocd/testapp-application.yaml` — Argo CD Application manifest

See per-folder README-like comments for specifics.
