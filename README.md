# SAGAMBA EKS Manifests

Standalone repository for SAGAMBA Kubernetes manifests targeting **AWS EKS**. Use this repo separately from the main application codebase so you can version and deploy infrastructure independently.

## Use as a separate Git repo

This folder is intended to be its own Git repository:

```bash
cd sagamba-eks-manifests
git init
git add .
git commit -m "Initial EKS manifests for SAGAMBA"
git remote add origin https://github.com/YOUR_ORG/sagamba-eks-manifests.git
git push -u origin main
```

Clone it elsewhere when you only need to manage deployments:

```bash
git clone https://github.com/YOUR_ORG/sagamba-eks-manifests.git
cd sagamba-eks-manifests
kubectl apply -f namespace.yaml
# ... etc
```

---

# SAGAMBA on AWS EKS

Kubernetes manifests for running SAGAMBA on **AWS EKS** with horizontal scaling (HPA).

## Contents

| File | Description |
|------|-------------|
| `namespace.yaml` | `sagamba` namespace |
| `configmap.yaml` | Shared config (DB, Redis, RabbitMQ, Eureka hosts) |
| `secrets.yaml` | **Template** – replace values; prefer AWS Secrets Manager + External Secrets in prod |
| `postgres.yaml` | PostgreSQL + PVC (storageClass: efs-sc) |
| `redis.yaml` | Redis + PVC |
| `rabbitmq.yaml` | RabbitMQ + PVC |
| `service-registry.yaml` | Eureka |
| `api-gateway.yaml` | API Gateway + Service + HPA |
| `auth-service.yaml` | Auth service + Service + HPA |
| `organization-service.yaml` | Organization service (Service name: `sagamba-organization-service`) + HPA |
| `beneficiary-iga-services.yaml` | Beneficiary + IGA + Services + HPAs |
| `group-loan-services.yaml` | Group + Loan + Services + HPAs |
| `poverty-assessment-report-audit-services.yaml` | Poverty, Assessment, Report, Audit + Services + HPAs |
| `frontend.yaml` | Next.js frontend + Service + HPA |
| `ingress.yaml` | AWS ALB Ingress (requires AWS Load Balancer Controller) |

## Prerequisites

- **EKS cluster** (1.24+)
- **kubectl** configured for the cluster
- **AWS Load Balancer Controller** installed (for Ingress/ALB)
- **OIDC / IRSA** if using private container registry
- **Storage**: PVCs use `storageClassName: efs-sc`; change to `efs-sc` or your default if needed

## Image registry

Manifests use `ghcr.io/fistonfle/sagamba-*:latest`. Replace with your registry:

```bash
# Example: replace for ECR
export REGISTRY=123456789012.dkr.ecr.eu-west-1.amazonaws.com
export IMAGE_TAG=latest

sed -e "s|ghcr.io/fistonfle/sagamba-|${REGISTRY}/sagamba-|g" -e "s|:latest|:${IMAGE_TAG}|g" -i *.yaml
# Or use kustomize (see below)
```

## Apply order

Apply in this order so dependencies (Eureka, DB, Redis, RabbitMQ) are up before services:

```bash
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml

# Infrastructure
kubectl apply -f postgres.yaml
kubectl apply -f redis.yaml
kubectl apply -f rabbitmq.yaml

# Wait for DB/Redis/RabbitMQ to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n sagamba --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n sagamba --timeout=120s
kubectl wait --for=condition=ready pod -l app=rabbitmq -n sagamba --timeout=120s

# Eureka first (services register here)
kubectl apply -f service-registry.yaml
kubectl wait --for=condition=ready pod -l app=service-registry -n sagamba --timeout=120s

# API Gateway and microservices (can be applied in parallel)
kubectl apply -f api-gateway.yaml
kubectl apply -f auth-service.yaml
kubectl apply -f organization-service.yaml
kubectl apply -f beneficiary-iga-services.yaml
kubectl apply -f group-loan-services.yaml
kubectl apply -f poverty-assessment-report-audit-services.yaml
kubectl apply -f frontend.yaml

# Ingress (after AWS LB controller is installed)
kubectl apply -f ingress.yaml
```

## One-shot apply (after first-time setup)

```bash
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml
kubectl apply -f postgres.yaml
kubectl apply -f redis.yaml
kubectl apply -f rabbitmq.yaml
kubectl apply -f service-registry.yaml
kubectl apply -f api-gateway.yaml
kubectl apply -f auth-service.yaml
kubectl apply -f organization-service.yaml
kubectl apply -f beneficiary-iga-services.yaml
kubectl apply -f group-loan-services.yaml
kubectl apply -f poverty-assessment-report-audit-services.yaml
kubectl apply -f frontend.yaml
kubectl apply -f ingress.yaml
```

## Scaling

- **HPA** is set for API Gateway and all microservices (min 2, max 8; frontend max 6). Adjust `minReplicas`/`maxReplicas` and `averageUtilization` in each HPA as needed.
- Manual scaling: `kubectl scale deployment auth-service --replicas=5 -n sagamba`

## Ingress and TLS

1. Edit `ingress.yaml`: replace `api.sagamba.example.com` and `app.sagamba.example.com` with your domains.
2. For HTTPS, create an ACM certificate and add:
   - `alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...`
   - `alb.ingress.kubernetes.io/ssl-redirect: "443"`
3. Point DNS for those hosts to the ALB (CNAME or alias).

## Frontend API URL

`NEXT_PUBLIC_API_URL` is baked into the Next.js build. Build the frontend image with the correct API URL for this environment, e.g.:

```bash
docker build --build-arg NEXT_PUBLIC_API_URL=https://api.sagamba.example.com -t your-registry/sagamba-frontend:latest ./sagamba-frontend
```

## Secrets in production

Do not commit real secrets. Prefer:

- **AWS Secrets Manager** (or Parameter Store) + [External Secrets Operator](https://external-secrets.io/) to sync into a K8s Secret, or
- **EKS Secrets Store CSI** to mount secrets from Secrets Manager.

Then remove or override `secrets.yaml` so production values are never in git.

## Eureka and service names

Gateway routes use `lb://<service-id>`. Eureka service IDs must match K8s Service names:

- `auth-service` → Service `auth-service`
- `sagamba-organization-service` → Service `sagamba-organization-service`
- `beneficiary-service`, `iga-service`, etc. → same as deployment name

Pods register with Eureka; the gateway discovers instances and calls the corresponding K8s Service.

## Storage class

PVCs use `storageClassName: efs-sc`. If your EKS default is different or you use a custom driver, set `storageClassName` in each PVC or set a default StorageClass in the cluster.

## Useful commands

```bash
kubectl get pods,svc,hpa -n sagamba
kubectl logs -f deployment/api-gateway -n sagamba
kubectl describe ingress sagamba-ingress -n sagamba
```
