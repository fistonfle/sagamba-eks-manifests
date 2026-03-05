# Port-forward EKS infra to localhost for local development.
# Run in PowerShell from sagamba-eks-manifests (or set $env:NAMESPACE).
# Requires: kubectl, cluster access.

$ErrorActionPreference = "Stop"
$NS = if ($env:NAMESPACE) { $env:NAMESPACE } else { "sagamba" }

Write-Host "Port-forwarding EKS infra to localhost (namespace=$NS). Press Ctrl+C to stop." -ForegroundColor Cyan
Write-Host "  PostgreSQL: localhost:5432"
Write-Host "  Redis:      localhost:6379"
Write-Host "  RabbitMQ:   localhost:5672 (AMQP), localhost:15672 (UI)"
Write-Host "  pgAdmin:    http://localhost:5050"
Write-Host ""

# Pre-check: cluster and namespace
kubectl cluster-info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Cannot reach cluster. Check: kubectl config current-context" -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}
kubectl get ns $NS 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Namespace '$NS' not found." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

# Check if local ports are already in use (common cause of port-forward failure)
$ports = @(5432, 6379, 5672, 15672, 5050)
$inUse = @()
foreach ($p in $ports) {
    $conn = Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue
    if ($conn) { $inUse += $p }
}
if ($inUse.Count -gt 0) {
    Write-Host "WARNING: These local ports are already in use: $($inUse -join ', ')" -ForegroundColor Yellow
    Write-Host "Stop the app using them (e.g. local PostgreSQL, Redis) or see PORT_FORWARD_TROUBLESHOOTING.md" -ForegroundColor Yellow
    Write-Host ""
}

# Start each port-forward in a new window so all run in parallel
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n $NS svc/postgres-service 5432:5432; Read-Host 'Press Enter to close'" -WindowStyle Normal
Start-Sleep -Milliseconds 400
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n $NS svc/redis-service 6379:6379; Read-Host 'Press Enter to close'" -WindowStyle Normal
Start-Sleep -Milliseconds 400
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n $NS svc/rabbitmq-service 5672:5672 15672:15672; Read-Host 'Press Enter to close'" -WindowStyle Normal
Start-Sleep -Milliseconds 400
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n $NS svc/pgadmin 5050:80; Read-Host 'Press Enter to close'" -WindowStyle Normal

Write-Host "Four PowerShell windows opened (PostgreSQL, Redis, RabbitMQ, pgAdmin). Close those windows to stop." -ForegroundColor Green
Read-Host "Press Enter to close this window"
