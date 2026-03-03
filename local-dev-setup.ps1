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
Write-Host "Press any key to stop all port forwards" -ForegroundColor Yellow
Write-Host ""

# Kill any existing kubectl port-forward processes
Get-Process -Name kubectl -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# Start all port-forwards in background (non-blocking)
Start-Process -NoNewWindow -FilePath "kubectl" -ArgumentList "port-forward", "-n", "sagamba", "svc/postgres-service", "5432:5432"
Start-Process -NoNewWindow -FilePath "kubectl" -ArgumentList "port-forward", "-n", "sagamba", "svc/redis-service", "6379:6379"
Start-Process -NoNewWindow -FilePath "kubectl" -ArgumentList "port-forward", "-n", "sagamba", "svc/rabbitmq-service", "5672:5672", "15672:15672"
Start-Process -NoNewWindow -FilePath "kubectl" -ArgumentList "port-forward", "-n", "sagamba", "svc/pgadmin", "5050:80"
Start-Process -NoNewWindow -FilePath "kubectl" -ArgumentList "port-forward", "-n", "sagamba", "svc/service-registry-service", "8761:8761"

Write-Host "All port-forwards started. Press any key to stop." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Cleanup: stop kubectl processes
Get-Process -Name kubectl -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "Stopped all port-forwards." -ForegroundColor Yellow
