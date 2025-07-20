# 2025-07-20 CH41B01
# Test N8N Deployment

Write-Host "==================================" -ForegroundColor Green
Write-Host "TESTING N8N SECURE DEPLOYMENT" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

# Check Docker containers
Write-Host "`nCHECKING CONTAINERS..." -ForegroundColor Yellow
docker-compose -f docker-compose-working.yml ps

# Test N8N main interface
Write-Host "`nTESTING N8N INTERFACE..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ N8N Main Interface: WORKING (HTTP $($response.StatusCode))" -ForegroundColor Green
        Write-Host "   URL: http://localhost" -ForegroundColor White
    }
} catch {
    Write-Host "❌ N8N Main Interface: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test N8N with Basic Auth
Write-Host "`nTESTING N8N WITH AUTHENTICATION..." -ForegroundColor Yellow
try {
    $credential = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("admin:SecureN8NPassword123!"))
    $response = Invoke-WebRequest -Uri "http://localhost" -Headers @{Authorization="Basic $credential"} -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ N8N Authentication: WORKING (HTTP $($response.StatusCode))" -ForegroundColor Green
        Write-Host "   Username: admin" -ForegroundColor White
        Write-Host "   Password: SecureN8NPassword123!" -ForegroundColor White
    }
} catch {
    Write-Host "❌ N8N Authentication: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test Grafana
Write-Host "`nTESTING GRAFANA DASHBOARD..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Grafana Dashboard: WORKING (HTTP $($response.StatusCode))" -ForegroundColor Green
        Write-Host "   URL: http://localhost:3000" -ForegroundColor White
        Write-Host "   Username: admin" -ForegroundColor White
        Write-Host "   Password: SecureGrafanaAdmin789!" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Grafana Dashboard: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test Database Connection
Write-Host "`nTESTING DATABASE CONNECTION..." -ForegroundColor Yellow
try {
    $dbTest = docker exec n8n-postgres pg_isready -U n8n_secure_user -d n8n_secure_db
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ PostgreSQL Database: WORKING" -ForegroundColor Green
        Write-Host "   Database: n8n_secure_db" -ForegroundColor White
        Write-Host "   User: n8n_secure_user" -ForegroundColor White
    }
} catch {
    Write-Host "❌ PostgreSQL Database: FAILED" -ForegroundColor Red
}

Write-Host "`n==================================" -ForegroundColor Green
Write-Host "DEPLOYMENT TEST COMPLETE" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

Write-Host "`nTO ACCESS N8N:" -ForegroundColor Cyan
Write-Host "1. Open browser to: http://localhost" -ForegroundColor White
Write-Host "2. Login with: admin / SecureN8NPassword123!" -ForegroundColor White
Write-Host "`nTO ACCESS GRAFANA:" -ForegroundColor Cyan  
Write-Host "1. Open browser to: http://localhost:3000" -ForegroundColor White
Write-Host "2. Login with: admin / SecureGrafanaAdmin789!" -ForegroundColor White
