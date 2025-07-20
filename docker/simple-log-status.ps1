# 2025-07-20 CH41B01
# Simple N8N Logging Status Manager

Write-Host "N8N DEPLOYMENT & LOGGING STATUS" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green

# Check deployment status
Write-Host "`nCONTAINER STATUS:" -ForegroundColor Yellow
docker-compose -f docker-compose-fixed.yml ps

# Check log directories
Write-Host "`nLOGGING INFRASTRUCTURE:" -ForegroundColor Yellow
$logDir = "logs"
$services = @("n8n", "caddy", "postgres", "grafana", "aggregated", "security")

if (Test-Path $logDir) {
    foreach ($svc in $services) {
        $path = "$logDir/$svc"
        if (Test-Path $path) {
            $files = Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue
            if ($files) {
                $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
                $sizeInMB = [math]::Round($totalSize / 1MB, 2)
                Write-Host "  $svc`: $($files.Count) files, ${sizeInMB}MB" -ForegroundColor Green
            } else {
                Write-Host "  $svc`: No log files yet" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  $svc`: Directory not found" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  Log directory not found: $logDir" -ForegroundColor Red
}

# Test connectivity
Write-Host "`nCONNECTIVITY TEST:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "  Health Check: PASS ($($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "  Health Check: FAIL - $($_.Exception.Message)" -ForegroundColor Red
}

# Show access information
Write-Host "`nACCESS INFORMATION:" -ForegroundColor Cyan
Write-Host "  N8N Interface: https://localhost" -ForegroundColor White
Write-Host "  Username: admin_6290" -ForegroundColor White
Write-Host "  Password: SecureRandomP@ssw0rd2025!" -ForegroundColor White
Write-Host ""
Write-Host "  Grafana Dashboard: https://localhost/grafana" -ForegroundColor White
Write-Host "  Username: admin" -ForegroundColor White
Write-Host "  Password: Gr@fanaS3cur3P@ss2025!" -ForegroundColor White

# Log management commands
Write-Host "`nLOG MANAGEMENT COMMANDS:" -ForegroundColor Blue
Write-Host "  View all logs: docker-compose -f docker-compose-fixed.yml logs" -ForegroundColor White
Write-Host "  View N8N logs: docker logs n8n-app-fixed" -ForegroundColor White
Write-Host "  View live logs: docker-compose -f docker-compose-fixed.yml logs -f" -ForegroundColor White
Write-Host "  Log directory: $((Get-Item $logDir -ErrorAction SilentlyContinue).FullName)" -ForegroundColor White
