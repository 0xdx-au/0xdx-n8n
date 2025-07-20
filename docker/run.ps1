# 2025-07-20 CH41B01
# Simple N8N Deployment Script

param(
    [switch]$Test,
    [switch]$Stop,
    [switch]$Status,
    [switch]$Logs,
    [switch]$Secure
)

Write-Host "N8N Deployment Manager" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green

# Set working directory
Set-Location $PSScriptRoot

if ($Stop) {
    Write-Host "Stopping N8N deployment..." -ForegroundColor Yellow
    if ($Secure) {
        docker-compose -f docker-compose.secure.yml --env-file .env.secure down -v
    } else {
        docker-compose -f docker-compose-test.yml down -v
    }
    Write-Host "N8N deployment stopped" -ForegroundColor Green
    return
}

if ($Status) {
    Write-Host "N8N deployment status:" -ForegroundColor Cyan
    if ($Secure) {
        docker-compose -f docker-compose.secure.yml --env-file .env.secure ps
    } else {
        docker-compose -f docker-compose-test.yml ps
    }
    return
}

if ($Logs) {
    Write-Host "N8N deployment logs:" -ForegroundColor Cyan
    if ($Secure) {
        docker-compose -f docker-compose.secure.yml --env-file .env.secure logs -f
    } else {
        docker-compose -f docker-compose-test.yml logs -f
    }
    return
}

if ($Test) {
    Write-Host "Starting N8N test deployment..." -ForegroundColor Yellow
    
    # Check Docker
    try {
        docker --version | Out-Null
    } catch {
        Write-Host "ERROR: Docker not found. Please install Docker Desktop" -ForegroundColor Red
        exit 1
    }
    
    # Start test deployment
    Write-Host "Starting test containers..." -ForegroundColor Green
    docker-compose -f docker-compose-test.yml up -d
    
    # Wait for startup
    Start-Sleep 10
    
    # Show status
    docker-compose -f docker-compose-test.yml ps
    
    Write-Host "Test deployment started successfully!" -ForegroundColor Green
    Write-Host "Access N8N at: http://localhost:5678" -ForegroundColor Cyan
    return
}

if ($Secure) {
    Write-Host "Starting secure N8N deployment..." -ForegroundColor Yellow

    # Validate environment
    if (!(Test-Path ".env.secure")) {
        Write-Host "ERROR: .env.secure file not found!" -ForegroundColor Red
        exit 1
    }

    # Check Docker
    try {
        docker --version | Out-Null
        docker-compose --version | Out-Null
    } catch {
        Write-Host "ERROR: Docker or Docker Compose not found" -ForegroundColor Red
        exit 1
    }

    # Create volumes
    Write-Host "Creating volume directories..." -ForegroundColor Blue
    $volumeDirs = @(
        "volumes/caddy/data", "volumes/caddy/config",
        "volumes/n8n/data", "volumes/n8n/logs", 
        "volumes/postgres/data", "volumes/prometheus/data",
        "volumes/grafana/data", "volumes/zap/data"
    )

    foreach ($dir in $volumeDirs) {
        New-Item -ItemType Directory -Path $dir -Force -ErrorAction SilentlyContinue | Out-Null
    }

    # Start services
    Write-Host "Starting secure services..." -ForegroundColor Green
    docker-compose -f docker-compose.secure.yml --env-file .env.secure up -d --build

    # Show status
    Write-Host "Deployment status:" -ForegroundColor Cyan
    docker-compose -f docker-compose.secure.yml --env-file .env.secure ps

    Write-Host ""
    Write-Host "N8N Secure Deployment Started!" -ForegroundColor Green
    Write-Host "N8N Interface: https://localhost" -ForegroundColor Cyan
    Write-Host "Grafana Dashboard: https://localhost/grafana" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Default Credentials:" -ForegroundColor Yellow
    Write-Host "  N8N: admin / SecureN8NPassword123!" -ForegroundColor White
    Write-Host "  Grafana: admin / SecureGrafanaAdmin789!" -ForegroundColor White
} else {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  Test deployment:   .\run.ps1 -Test" -ForegroundColor White
    Write-Host "  Secure deployment: .\run.ps1 -Secure" -ForegroundColor White
    Write-Host "  Stop deployment:   .\run.ps1 -Stop [-Secure]" -ForegroundColor White
    Write-Host "  Check status:      .\run.ps1 -Status [-Secure]" -ForegroundColor White
    Write-Host "  View logs:         .\run.ps1 -Logs [-Secure]" -ForegroundColor White
}
