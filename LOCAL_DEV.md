# Local development with EKS (port-forward)

When you run **auth-service** (or any backend) from IntelliJ/PowerShell with **profile `dev`** and **DB_HOST=localhost**, the app connects to PostgreSQL on **localhost:5432**. That only works if a **port-forward** from EKS to your machine is running.

## "Connection to localhost:5432 refused"

This means **nothing is listening on port 5432** on your machine. Fix it by starting the port-forward **before** running the app.

### 1. Start port-forward (keep this terminal open)

**PowerShell (Windows):**
```powershell
cd sagamba-eks-manifests
.\local-dev-setup.ps1
```

**Bash (Linux/macOS/WSL):**
```bash
cd sagamba-eks-manifests
./port-forward-infra.sh
```

You should see something like:
- `Forwarding from 127.0.0.1:5432 -> 5432` (and similar for Redis, RabbitMQ, etc.)
- In PowerShell with the updated script: `PostgreSQL port-forward is active (localhost:5432).`

Leave this terminal/window open. Closing it or pressing the stop key will kill the forwards.

### 2. Check that 5432 is listening (optional)

**PowerShell:**
```powershell
Get-NetTCPConnection -LocalPort 5432 -State Listen -ErrorAction SilentlyContinue
```
If this returns nothing, the port-forward is not active.

**Bash:**
```bash
# Linux/macOS
nc -zv localhost 5432
# or
ss -tlnp | grep 5432
```

### 3. Run your app

- IntelliJ: run **AuthServiceApplication** with profile **dev** and env from `.env` + `.env.local` (so `DB_HOST=localhost`).
- Or from the **sagamba-microservices** directory with env vars set.

### 4. If port-forward fails

- Ensure **kubectl** is in your PATH and your kubeconfig points to the EKS cluster:
  ```powershell
  kubectl get pods -n sagamba
  ```
- Ensure **PostgreSQL** is running in the cluster:
  ```powershell
  kubectl get pods -n sagamba -l app=postgres
  ```
- If the service name is different (e.g. `postgres` not `postgres-service`), adjust the script to use the correct service name.

## Summary

| Problem | Cause | Fix |
|--------|--------|-----|
| Connection to localhost:5432 **refused** | Port-forward not running or stopped | Start `.\local-dev-setup.ps1` (or `./port-forward-infra.sh`) and keep it open |
| Connection **timed out** (to EKS hostname) | Using EKS LB from your machine; SG or network blocks | Use port-forward + localhost, or open SG for your IP |
| **Read timed out** (SSL) | SSL handshake over port-forward | Use profile `dev` (datasource has `?sslmode=disable`) |
