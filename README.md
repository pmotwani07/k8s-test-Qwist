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


# Argo CD Setup Guide

This guide documents the **manual steps** required to set up Argo CD on the EKS cluster and deploy workloads using GitOps.  
All other infrastructure provisioning (EKS cluster, VPC, node groups) is automated via Terraform.

---

## 1. Configure `kubectl` for EKS

After Terraform creates the cluster, update your local kubeconfig:

bash

aws eks update-kubeconfig --region <AWS_REGION> --name <CLUSTER_NAME>

In our case

aws eks update-kubeconfig --region eu-central-1 --name eks-cluster

Verify the Connection

kubectl get nodes


You should see the nodes created by EKS Auto Mode.

## 2 Install Argo CD

Create the argocd namespace:

kubectl create namespace argocd

Install Argo CD components:

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


## 3. Expose the Argo CD API Server

Setup argocd-server service to use a LoadBalancer:

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

Wait a few minutes and get the external URL:

kubectl get svc argocd-server -n argocd

Copy the EXTERNAL-IP value — this is the Argo CD UI endpoint.

## 4. Retrieve Initial Admin Password

kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 --decode && echo

## 5. Access the Argo CD UI

  Open the LoadBalancer URL in your browser (HTTPS).
  Log in with:

  Username: admin

  Password: (from step 4)

  ⚠️ You may see a browser security warning due to the self-signed certificate.
  It is safe to continue for now, but a proper TLS cert can be configured later.

## 6. Deploy Applications

Create an Argo CD Application manifest to point to your Helm chart repository.
For example, to deploy the charts/testapp chart:

```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: testapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "https://github.com/pmotwani07/k8s-test-Qwist"
    targetRevision: HEAD
    path: charts/testapp
  destination:
    server: https://kubernetes.default.svc
    namespace: testapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Apply the manifest:

kubectl apply -f testapp-application.yaml


Your application will automatically sync and deploy into the testapp namespace.

## Add Nginx Ingress controller on k8s cluster_id
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install in its own namespace
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
