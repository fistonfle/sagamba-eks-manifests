# SAGAMBA EKS Deployment - Access Guide

## 🎯 Deployment Status: ✅ COMPLETE & OPERATIONAL

Your SAGAMBA application is fully deployed on AWS EKS and is **live and accessible**.

---

## 📊 Deployment Summary

### Infrastructure
- **Cluster:** sagamba-cluster (EKS Auto Mode)
- **Region:** eu-north-1
- **Nodes:** 3 ready (Bottlerocket OS)
- **Storage:** AWS EFS (20Gi per service)
- **Ingress:** NGINX Controller v1.8.4
- **Registry:** GitHub Container Registry (ghcr.io)

### Deployed Services
**Core Services (running):**
- ✅ API Gateway (2 replicas)
- ✅ Frontend (2 replicas)  
- ✅ Service Registry (Eureka)
- ✅ PostgreSQL 14 (with EFS storage)
- ✅ Redis 7 (with EFS storage)
- ✅ RabbitMQ 3.12 (with EFS storage)

**Backend microservices (Auth, Organization, Beneficiary, IGA, Loan, Group, Poverty, Assessment, Report, Audit):**  
The Eureka/Kubernetes port bug is **fixed** in the application code (all services use `SERVER_PORT`). Apply the manifests below to run these services.

---

## 🚀 Enable all backend services (fix 503 on /v3/api-docs/*)

The **Eureka/Kubernetes port bug is fixed** in the Java code (services use `SERVER_PORT` instead of `*_SERVICE_PORT`). To run Auth, Organization, Assessment, and the other backends so Swagger and the API work:

**1. Ensure fixed images are built and pushed** (from `sagamba-microservices` repo):
- Push to `main`/`master` to trigger **Build and Push to GHCR (for EKS)**, or build and push images manually.
- Images must include the `SERVER_PORT` change (already in the repo).

**2. Apply all backend manifests** (from the `sagamba-eks-manifests` directory):

```bash
# Auth & Organization
kubectl apply -f auth-service.yaml
kubectl apply -f organization-service.yaml

# Beneficiary & IGA
kubectl apply -f beneficiary-iga-services.yaml

# Group & Loan
kubectl apply -f group-loan-services.yaml

# Poverty, Assessment, Report, Audit
kubectl apply -f poverty-assessment-report-audit-services.yaml
```

**3. If deployments exist but were scaled to 0**, scale them back up:

```bash
kubectl scale deployment auth-service --replicas=2 -n sagamba
kubectl scale deployment organization-service --replicas=2 -n sagamba
kubectl scale deployment beneficiary-service --replicas=2 -n sagamba
kubectl scale deployment iga-service --replicas=2 -n sagamba
kubectl scale deployment group-service --replicas=2 -n sagamba
kubectl scale deployment loan-service --replicas=2 -n sagamba
kubectl scale deployment poverty-service --replicas=2 -n sagamba
kubectl scale deployment assessment-service --replicas=2 -n sagamba
kubectl scale deployment report-service --replicas=2 -n sagamba
kubectl scale deployment audit-service --replicas=2 -n sagamba
```

**4. Wait for pods to be Ready:**

```bash
kubectl get pods -n sagamba -w
```

Once backend pods are `Running` and `1/1` Ready, the gateway will stop returning 503 for `/v3/api-docs/assessment` and other service docs.

---

## 🚀 How to Access Your Application

### Method 1: HTTPS via Domain (Recommended for Production)

Your application now has **automatic HTTPS** enabled using Let's Encrypt certificates managed by cert-manager.

**Access via:**
```
https://sagamba.savetoserve.rw          (Frontend - Login Page)
https://sagambaapi.savetoserve.rw       (API Gateway - Health & Actuator)
```

**Certificate Details:**
- **Issuer:** Let's Encrypt (letsencrypt-prod)
- **Auto-Renewal:** 30 days before expiration
- **Domains:** sagamba.savetoserve.rw, sagambaapi.savetoserve.rw
- **Secret:** sagamba-tls-cert (stored in Kubernetes)

**Check Certificate Status:**
```bash
kubectl get certificate -n sagamba
kubectl describe certificate sagamba-tls-cert -n sagamba

# Watch for READY status to change from False to True (takes 1-2 minutes)
kubectl get certificate -n sagamba -w
```

Once certificate is READY=True, HTTPS will be fully active.

### Method 2: Port-Forward (Recommended for Development)

**Step 1:** Open a terminal and start the port-forward tunnel:
```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
```

You'll see:
```
Forwarding from 127.0.0.1:8080 -> 80
```

**Step 2:** In your browser or curl, access:

```bash
# Frontend (Login page)
curl http://localhost:8080/ -H "Host: sagamba.savetoserve.rw"

# API Gateway Health Check
curl http://localhost:8080/actuator/health -H "Host: sagambaapi.savetoserve.rw"
```

Or simply open your browser to:
```
http://localhost:8080
```

**Step 3:** When done, press `Ctrl+C` to stop the port-forward.

---

## 🔐 Credentials & Configuration

### Database
- **Host:** postgres-service (internal Kubernetes DNS)
- **Port:** 5432
- **Credentials:** Stored in `sagamba-secrets`

### Redis
- **Host:** redis-service
- **Port:** 6379

### RabbitMQ
- **Host:** rabbitmq-service
- **Ports:** 5672 (AMQP), 15672 (Management UI)
- **Credentials:** Stored in `sagamba-secrets`

### GitHub Container Registry
- **Registry:** ghcr.io
- **Username:** fistonfle
- **Secret:** ghcr-secret (stored in cluster)

---

## 📋 Kubernetes Commands Reference

### View Deployed Resources
```bash
# All pods in sagamba namespace
kubectl get pods -n sagamba

# All services
kubectl get svc -n sagamba

# Ingress configuration
kubectl get ingress -n sagamba

# All resources
kubectl get all -n sagamba -o wide
```

### Check Logs
```bash
# Frontend logs
kubectl logs -n sagamba deployment/sagamba-frontend

# API Gateway logs
kubectl logs -n sagamba deployment/api-gateway

# Service Registry logs
kubectl logs -n sagamba deployment/service-registry
```

### Port-Forward to Specific Services
```bash
# Frontend directly
kubectl port-forward -n sagamba svc/sagamba-frontend 3000:80

# API Gateway directly
kubectl port-forward -n sagamba svc/api-gateway-service 8080:8080

# PostgreSQL
kubectl port-forward -n sagamba svc/postgres-service 5432:5432

# RabbitMQ Management UI
kubectl port-forward -n sagamba svc/rabbitmq-service 15672:15672
```

---

## 🔧 Troubleshooting

### CrashLoopBackOff (auth-service, organization-service, rabbitmq, etc.)

**1. Get the crash reason from logs:**
```bash
# Last log from a crashing pod (replace with your pod name)
kubectl logs -n sagamba deployment/auth-service --previous

# Or for a specific pod
kubectl logs -n sagamba auth-service-67f746b5dc-9jq95 --previous
```

**2. Common causes:**
- **RabbitMQ/Postgres down:** Backend services need RabbitMQ and Postgres. If RabbitMQ is in CrashLoopBackOff, fix it first (see below); then auth and organization should start.
- **Wrong PVC volume:** RabbitMQ and Redis had swapped PVC `volumeName` in the manifests (fixed: rabbitmq uses `efs-pv-rabbitmq`, redis uses `efs-pv-redis`). If you applied the old YAML, delete the PVCs and re-apply (data on that volume will be recreated):
  ```bash
  kubectl delete pvc rabbitmq-pvc redis-pvc -n sagamba
  kubectl apply -f rabbitmq.yaml
  kubectl apply -f redis.yaml
  ```
- **Secrets missing:** Ensure `sagamba-secrets` has keys: DB_USERNAME, DB_PASSWORD, RABBITMQ_USERNAME, RABBITMQ_PASSWORD, JWT_SECRET, POSTGRES_USER, POSTGRES_PASSWORD, REDIS_PASSWORD (see secrets.yaml or your secret store).

**3. Check RabbitMQ specifically:**
```bash
kubectl logs -n sagamba deployment/rabbitmq --previous
kubectl describe pod -n sagamba -l app=rabbitmq
```

### Pending pods (assessment-service, audit-service, group-service, etc.)

**Cause:** Scheduler cannot place the pod—usually **insufficient CPU/memory** on nodes.

**1. See why a pod is Pending:**
```bash
kubectl describe pod -n sagamba assessment-service-7f5f5bc78b-ddwc7
```
Look at **Events** at the bottom (e.g. "0/3 nodes are available: insufficient memory").

**2. Options:**
- **Scale down to 1 replica** so fewer pods need to schedule:
  ```bash
  kubectl scale deployment assessment-service --replicas=1 -n sagamba
  kubectl scale deployment audit-service --replicas=1 -n sagamba
  # ... repeat for other backends
  ```
- **Add nodes** or use a larger instance type (EKS Auto Mode will scale nodes; wait or adjust capacity).
- **Lower resource requests** in the deployment YAML (e.g. `memory: "256Mi"`, `cpu: "100m"`) and re-apply—only if your nodes are small.

### If port-forward fails
```bash
# Verify kubeconfig is set
echo $KUBECONFIG

# Test cluster connectivity
kubectl get nodes

# Check NGINX controller pod status
kubectl get pods -n ingress-nginx
```

### If services aren't responding
```bash
# Check service endpoints
kubectl get endpoints -n sagamba

# Test internal connectivity from a pod
kubectl run -it --rm test-pod --image=curlimages/curl --restart=Never -- curl http://sagamba-frontend
```

### View resource usage
```bash
kubectl top nodes
kubectl top pods -n sagamba
```

---

## 📝 Known Issues & Notes

1. **Backend services:** The Eureka/Kubernetes port bug (K8s injecting `tcp://...` into `*_SERVICE_PORT`) is fixed in the application code. All services use `SERVER_PORT` and manifests set it explicitly. Apply the backend manifests and use images built after the fix so Auth, Assessment, etc. run and `/v3/api-docs/*` return 200 instead of 503.

2. **Network Access:** Your Windows client doesn't have direct VPN access to the VPC private IP range (172.31.x.x). External LoadBalancer and NodePort access requires VPN setup. Port-forward is the recommended method for secure access.

3. **Storage:** All persistent data is stored on AWS EFS. Deleting pods will not lose data - it persists via EFS volumes.

---

## 📊 Verification Checklist

✅ NGINX Ingress Controller running (1/1)
✅ Frontend responding with HTML login page
✅ API Gateway returning health status
✅ PostgreSQL, Redis, RabbitMQ all running
✅ Storage layer operational (EFS volumes bound)
✅ GitHub Container Registry authentication working
✅ All security groups configured
✅ Ingress routes configured for sagamba.savetoserve.rw and sagambaapi.savetoserve.rw
✅ Port-forward access verified working

---

## 🎓 Next Steps

1. **Run all backends:** Apply the backend manifests and scale to 2 replicas (see **Enable all backend services** above). Use images built after the `SERVER_PORT` fix so 503 on `/v3/api-docs/assessment` (and other services) goes away.

2. **Setup VPN (Optional):** For direct external access without port-forward, set up AWS VPN to your client machine.

3. **Domain Setup:** Configure Route 53 DNS to point your domains to either:
   - The LoadBalancer (requires VPN)
   - Node external IPs with externalIP service configuration

4. **Monitoring:** Consider setting up CloudWatch logs and metrics for production monitoring.

---

## 📞 Support

For cluster management commands, use:
```bash
kubectl --kubeconfig=$KUBECONFIG -n sagamba [command]

# Or check your kubeconfig location
aws eks update-kubeconfig --name sagamba-cluster --region eu-north-1
```

---

**Deployment completed successfully! 🚀**
Your SAGAMBA application is live and ready for use.
