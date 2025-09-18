# Kubernetes Tech Challenge

## The setup described below has been done on AWS, but it can also be implemented on GCP or Azure. All objects and services mentioned (except standard tools like Helm, ArgoCD, Git, etc.) are AWS services.

##Components

AWS + Helm + Argo CD + Terraform + GitHub Actions


This repository provides a complete reference implementation that:

- Provisions an **AWS EKS** cluster with **Terraform** (uses terraform-aws-modules/eks/aws)
- Packages and deploys a sample app using a **Helm** chart
- Uses **Ingress NGINX** as the reverse proxy (installed via Helm)
- Enables scaling via a **Horizontal Pod Autoscaler (HPA)**
- Uses **Argo CD** for GitOps and to watch the Helm chart (sync Helm chart from repo)
- Provides a **GitHub Actions** CI pipeline that builds a container image, pushes to docker repository, updates the Helm values (image tag) and triggers Argo CD to sync

## What is included
- `app/` — simple Flask app + Dockerfile
- `charts/testapp/` — Helm chart for the app (deployment, service, hpa, ingress)
- `terraform/aws/` — Terraform code to provision VPC, EKS cluster, node groups (uses terraform-aws-modules)
- `.github/workflows/ci-cd.yml` — GitHub Actions workflow for CI/CD
- `argocd/` — Argo CD Application manifest pointing to `charts/testapp`
- `Makefile` — helper targets for local testing and Terraform commands
- .gitignore files
- nginx-controller.yaml file for deploying nginx ingress controller setup , reference took from official documentation here

https://kubernetes.github.io/ingress-nginx/deploy/#aws

## Important notes (read before running)
- **Do not commit sensitive credentials.** Use GitHub Secrets for CI (AWS keys, ECR, Argo CD token, DockerHub if used). I have used them securely .

- Terraform backend is configured to use an S3 bucket — replace `backend.tf` values with your own bucket and region.( I have used my own AWS playground account here)

- The Docker Repo setup in CI expects the repository to exist, I have tagged and pushed the image to my own docker repo , you can also use ECR for the purpose .

- The Terraform `eks` module version and AWS provider versions are pinned in `versions.tf`. Update to any other version if in case required. I have used the updated ones already here .

## Quick flow (high-level)
1. Create Terraform backend S3 bucket and DynamoDB table for locking (or update `terraform/backend.tf`).
2. `terraform init && terraform apply` in `terraform/aws` to create EKS cluster and outputs.
3. Install `kubectl`, `helm`, and `aws` CLI locally; configure `aws` credentials.
4. Add `ingress-nginx` and `argocd` separately ( done that manually for now ), steps are mentioned below .
5. Use GitHub Actions on push to `main` to build/push image to ECR and update Helm values.
6. Argo CD will sync the chart from this repository and deploy the new image tag.


## Files of interest
- `terraform/aws/main.tf` — EKS provisioning
- `charts/testapp/` — Helm chart including Ingress file also for deploying Ingress object.
- `.github/workflows/ci-cd.yml` — CI/CD
- `argocd/testapp-application.yaml` — Argo CD Application manifest


# Argo CD Setup Guide

This guide documents the **manual steps** required to set up Argo CD on the EKS cluster and deploy workloads using GitOps.  
All other infrastructure provisioning (EKS cluster, VPC, node groups) is automated via Terraform.

---

 1. Configure `kubectl` for EKS

After Terraform creates the cluster, update your local kubeconfig:

bash

aws eks update-kubeconfig --region <AWS_REGION> --name <CLUSTER_NAME>

In our case

aws eks update-kubeconfig --region eu-central-1 --name eks-cluster

Verify the Connection

kubectl get nodes


You should see the nodes created by EKS Auto Mode.

2.  Install Argo CD

Create the argocd namespace:

kubectl create namespace argocd

Install Argo CD components:

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


 3. Expose the Argo CD API Server

Setup argocd-server service to use a LoadBalancer:

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

Wait a few minutes and get the external URL:

kubectl get svc argocd-server -n argocd

Copy the EXTERNAL-IP value — this is the Argo CD UI endpoint.

 4. Retrieve Initial Admin Password

```kubectl get secret argocd-initial-admin-secret -n argocd
-o jsonpath="{.data.password}" | base64 --decode && echo
```

 5. Access the Argo CD UI

  Open the LoadBalancer URL in your browser (HTTPS).
  Log in with:

  Username: admin

  Password: (from step 4)

  ⚠️ You may see a browser security warning due to the self-signed certificate.
  It is safe to continue for now, but a proper TLS cert can be configured later.

 6. Deploy Applications

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

# Nginx Ingress Controller Setup

This is the official documentation used for deploy

https://kubernetes.github.io/ingress-nginx/deploy/#aws

1. Download the deploy.yaml file , I have renamed it to nginx-Controller.yaml to make it realistic
2. Update the placeholders values for certificates and CIDR range ( Please read next section for fetching Certificates value )
3. Add this annotation service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing" at line 351 so that NLB is external facing
4. Make sure your AWS Subnets are properly tagged with  Key	kubernetes.io/role/elb and value	1
5. install with kubectl apply -f nginx-controller.yaml
6. Check the status with command

```rishaanavni@Pankajs-MacBook-Air charts % kubectl get all -n ingress-nginx
NAME                                           READY   STATUS    RESTARTS   AGE
pod/ingress-nginx-controller-b9ccc9854-zdnfn   1/1     Running   0          146m

NAME                                         TYPE           CLUSTER-IP      EXTERNAL-IP                                                                        PORT(S)                      AGE
service/ingress-nginx-controller             LoadBalancer   172.20.235.45   k8s-ingressn-ingressn-24854de0b1-46db8018397013ac.elb.eu-central-1.amazonaws.com   80:30339/TCP,443:30785/TCP   124m
service/ingress-nginx-controller-admission   ClusterIP      172.20.39.56    <none>                                                                             443/TCP                      178m

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ingress-nginx-controller   1/1     1            1           178m

NAME                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/ingress-nginx-controller-5bb8b5db5c   0         0         0       178m
replicaset.apps/ingress-nginx-controller-b9ccc9854    1         1         1       146m
```
7 . You will see something like above under External that is external service type LB has now been created

## AWS Side of Things - manually ( Required for ACM and DNS Name resolution.)

1. Create a Route 53 Hosted Zone

Zone name: k8stestapp.element.in.

2. Create and Validate ACM Certificates

Follow AWS documentation to create the required DNS records for validation.

After validation, verify that the ACM certificate is in the “Issued” state.

Copy ACM ARN

Once validated, copy the ARN of the ACM certificate.

3. Configure NGINX Ingress Controller

Use the ACM ARN from the previous step in the NGINX Ingress setup to enable HTTPS access for your application.

Create a CNAME Record

Create a CNAME record for testapp.k8stestapp.element.in pointing to the NLB (Network Load Balancer) endpoint created in AWS.

4. Verify Application Access

Once DNS propagation completes, the application will be accessible at testapp.k8stestapp.element.in.

Traffic will be routed through the NGINX reverse proxy via Ingress and NLB, ensuring secure and proper routing of requests.


## Future Improvements

This setup is intended for **test purposes**. For production use cases or setups running multiple services, the following enhancements could make the environment **more secure, maintainable, and production-ready**:

- **Docker Security**
  - Add vulnerability scanning for Docker images.
  - Sign images in CI/CD pipelines.
  - Run containers as non-root users wherever possible.

- **Kubernetes Security**
  - Use **namespaces** to isolate workloads.
  - Implement **RBAC** (Role-Based Access Control) policies.
  - Use **Pod Admission Controllers** to enforce security best practices.

- **Pipeline Quality**
  - Run tests during the Docker build stage.
  - Add caching to speed up CI builds.
  - Include static analysis and linting in the pipeline.

- **Pipeline Refactoring**
  - Split the CI/CD workflow into multiple jobs (build, test, dockerize, deploy) to:
    - Improve parallelism.
    - Increase clarity.
    - Isolate failures.
  - Integrate notifications to teams via Slack or other chat tools on pipeline failures.

- **Deployment Reliability**
  - Add **liveness** and **readiness probes** for services.
  - Configure **resource requests and limits** for pods.
  - Enable **rollbacks** or **canary deployments** using Argo Rollouts.

- **Observability**
  - Implement centralized logging (e.g., ELK stack, Loki).
  - Add monitoring dashboards (Prometheus + Grafana).

- **Multi-App / Multi-Cluster Management**
  - Use the **Apps of Apps pattern** in ArgoCD for managing multiple applications or clusters efficiently.
