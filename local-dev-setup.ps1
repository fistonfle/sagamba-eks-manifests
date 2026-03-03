# Local Development Setup - Port-Forward to EKS Services (Windows)
# This script forwards all EKS infrastructure to localhost for local development

Write-Host "Starting port-forward to EKS services..." -ForegroundColor Green
Write-Host ""
Write-Host "Services will be available at:" -ForegroundColor Cyan
Write-Host "  PostgreSQL:   localhost:5432"
Write-Host "  Redis:        localhost:6379"
Write-Host "  RabbitMQ:     localhost:5672 (AMQP), localhost:15672 (UI)"
Write-Host "  pgAdmin:      http://localhost:5050"
Write-Host ""
Write-Host "Press any key to stop all port forwards" -ForegroundColor Yellow
Write-Host ""

# Kill any existing kubectl port-forward processes
Get-Process -Name kubectl -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# Start all port-forwards in background (non-blocking)
# Redirect stdout/stderr so AWS CLI "Invalid argument" on stop doesn't show in console (PowerShell requires different paths)
Start-Process -NoNewWindow -FilePath "kubectl" -ArgumentList "port-forward", "-n", "sagamba", "svc/postgres-service", "5432:5432" -RedirectStandardOutput "NUL" -RedirectStandardError "$env:TEMP\pf-postgres-err.log"
Start-Process -NoNewWindow -FilePath "kubectl" -ArgumentList "port-forward", "-n", "sagamba", "svc/redis-service", "6379:6379" -RedirectStandardOutput "NUL" -RedirectStandardError "$env:TEMP\pf-redis-err.log"
Start-Process -NoNewWindow -FilePath "kubectl" -ArgumentList "port-forward", "-n", "sagamba", "svc/rabbitmq-service", "5672:5672", "15672:15672" -RedirectStandardOutput "NUL" -RedirectStandardError "$env:TEMP\pf-rabbitmq-err.log"
Start-Process -NoNewWindow -FilePath "kubectl" -ArgumentList "port-forward", "-n", "sagamba", "svc/pgadmin", "5050:80" -RedirectStandardOutput "NUL" -RedirectStandardError "$env:TEMP\pf-pgadmin-err.log"

# EKS auth (e.g. aws eks get-token) can take several seconds; wait before checking
Start-Sleep -Seconds 10
$listener = Get-NetTCPConnection -LocalPort 5432 -State Listen -ErrorAction SilentlyContinue
if (-not $listener) {
    Write-Host "WARNING: localhost:5432 is not listening. Port-forward may still be starting (EKS auth can be slow) or may have failed." -ForegroundColor Red
    Write-Host "  Check: kubectl get pods -n sagamba -l app=postgres" -ForegroundColor Gray
    Write-Host "  Errors: $env:TEMP\pf-postgres-err.log" -ForegroundColor Gray
} else {
    Write-Host "PostgreSQL port-forward is active (localhost:5432)." -ForegroundColor Green
}

Write-Host "All port-forwards started. Press any key to stop." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Cleanup: stop kubectl processes
Get-Process -Name kubectl -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "Stopped all port-forwards." -ForegroundColor Yellow
