# Port-forward troubleshooting

When **kubectl port-forward** fails, use these checks.

---

## 1. Port already in use (most common on Windows)

**Symptom:** Error like `Unable to listen on port 5432: listen tcp 127.0.0.1:5432: bind: Only one usage of each socket address is normally permitted` or `address already in use`.

**Cause:** Another process is already using that port (e.g. local PostgreSQL on 5432, Redis on 6379, RabbitMQ on 5672/15672).

**Fix:**

- **Option A – Stop the local service**  
  Stop PostgreSQL/Redis/RabbitMQ (Services app, Task Manager, or `Stop-Service` / uninstall).

- **Option B – Use different local ports**  
  Forward to a different port on your machine, e.g.:
  ```powershell
  kubectl port-forward -n sagamba svc/postgres-service 15432:5432
  ```
  Then connect to `localhost:15432` instead of `localhost:5432`.

**Check what is using a port (PowerShell, run as Administrator):**
```powershell
Get-NetTCPConnection -LocalPort 5432 | Select-Object LocalAddress, LocalPort, OwningProcess
Get-Process -Id <OwningProcess>
```

---

## 2. Service or pod not ready

**Symptom:** Port-forward starts then exits immediately, or "connection refused" when you use the port.

**Cause:** The Service has no ready endpoints (backing pods not Ready).

**Check:**
```powershell
kubectl get endpoints -n sagamba
kubectl get pods -n sagamba -l app=postgres
```

If the pod is not `1/1 Running`, fix the pod first (e.g. `kubectl describe pod -n sagamba <pod-name>` and check logs).

---

## 3. Wrong service name or port

**Check service names and ports:**
```powershell
kubectl get svc -n sagamba
```

Use the **service name** (e.g. `postgres-service`, `redis-service`, `rabbitmq-service`, `pgadmin`) and the **port** from the service (e.g. 5432, 6379, 5672, 15672, 80 for pgadmin).

**Correct examples:**
```powershell
kubectl port-forward -n sagamba svc/postgres-service 5432:5432
kubectl port-forward -n sagamba svc/redis-service 6379:6379
kubectl port-forward -n sagamba svc/rabbitmq-service 5672:5672 15672:15672
kubectl port-forward -n sagamba svc/pgadmin 5050:80
```

---

## 4. Cluster not reachable

**Symptom:** `The connection to the server ... was refused` or timeout.

**Fix:** Refresh EKS kubeconfig and check context:
```powershell
aws eks update-kubeconfig --region eu-north-1 --name sagamba-cluster
kubectl config current-context
kubectl get nodes
```

---

## 5. Run from PowerShell (no Bash)

Use the PowerShell script so you don't depend on Git Bash:

```powershell
cd C:\Users\User\Documents\JOBS\SAGAMBA\codebase\sagamba-eks-manifests
.\port-forward-infra.ps1
```

It opens four windows (one per port-forward) and checks if local ports are already in use before starting.

---

## Quick reference: forward one service

| Service        | Command (local:remote)     | Use |
|----------------|----------------------------|-----|
| PostgreSQL     | `5432:5432`                | DB clients |
| Redis          | `6379:6379`                | Redis CLI / app |
| RabbitMQ AMQP  | `5672:5672`                | App |
| RabbitMQ UI    | `15672:15672`              | Browser |
| pgAdmin        | `5050:80`                  | http://localhost:5050 |

Example (single port-forward in current window):
```powershell
kubectl port-forward -n sagamba svc/pgadmin 5050:80
```
Ctrl+C stops it.
