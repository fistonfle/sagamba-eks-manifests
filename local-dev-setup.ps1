# Local Development Setup - Port-Forward to EKS Services (Windows)
# This script forwards all EKS infrastructure to localhost for local development

Write-Host "Starting port-forward to EKS services..." -ForegroundColor Green
Write-Host ""
Write-Host "Services will be available at:" -ForegroundColor Cyan
Write-Host "  PostgreSQL:   localhost:5432"
Write-Host "  Redis:        localhost:6379"
Write-Host "  RabbitMQ:     localhost:5672 (AMQP), localhost:15672 (UI)"
Write-Host "  pgAdmin:      http://localhost:5050"
Write-Host "  Eureka:       http://localhost:8761"
Write-Host ""
Write-Host "Press Ctrl+C to stop all port forwards" -ForegroundColor Yellow
Write-Host ""

# Kill any existing kubectl port-forward processes
Get-Process -Name kubectl -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# Start all port-forwards
Write-Host "Starting PostgreSQL port-forward (5432)..." -ForegroundColor Green
kubectl port-forward -n sagamba svc/postgres-service 5432:5432

Write-Host "All port-forwards starting! Keep this window open." -ForegroundColor Green
