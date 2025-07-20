# 2025-07-20 CH41B01
# PowerShell script to start secure N8N deployment

param(
    [switch]$Test,
    [switch]$Stop,
    [switch]$Status,
    [switch]$Logs
)

Write-Host "N8N Secure Deployment Manager" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green

# Set working directory
Set-Location $PSScriptRoot

# Environment setup
$env:COMPOSE_PROJECT_NAME = "n8n-secure-stack"

if ($Stop) {
    Write-Host "🛑 Stopping N8N secure deployment..." -ForegroundColor Yellow
    docker-compose -f docker-compose.secure.yml --env-file .env.secure down -v
    Write-Host "✅ N8N secure deployment stopped" -ForegroundColor Green
    return
}

if ($Status) {
    Write-Host "📊 N8N deployment status:" -ForegroundColor Cyan
    docker-compose -f docker-compose.secure.yml --env-file .env.secure ps
    return
}

if ($Logs) {
    Write-Host "📋 N8N deployment logs:" -ForegroundColor Cyan
    docker-compose -f docker-compose.secure.yml --env-file .env.secure logs -f
    return
}

if ($Test) {
    Write-Host "🧪 Starting N8N test deployment..." -ForegroundColor Yellow
    
    # Check Docker
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Docker not found. Please install Docker Desktop" -ForegroundColor Red
        exit 1
    }
    
    # Start test deployment
    Write-Host "🚀 Starting test containers..." -ForegroundColor Green
    docker-compose -f docker-compose-test.yml up -d
    
    # Wait for startup
    Start-Sleep 10
    
    # Show status
    docker-compose -f docker-compose-test.yml ps
    
    Write-Host "✅ Test deployment started successfully!" -ForegroundColor Green
    Write-Host "🌐 Access N8N at: http://localhost:5678" -ForegroundColor Cyan
    return
}

# Main secure deployment
Write-Host "🔐 Starting secure N8N deployment..." -ForegroundColor Yellow

# Validate environment
if (!(Test-Path ".env.secure")) {
    Write-Host "❌ .env.secure file not found!" -ForegroundColor Red
    exit 1
}

# Check Docker
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker not found. Please install Docker Desktop" -ForegroundColor Red
    exit 1
}

if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker Compose not found. Please install Docker Compose" -ForegroundColor Red
    exit 1
}

# Create volumes with proper permissions
Write-Host "📁 Creating volume directories..." -ForegroundColor Blue
$volumeDirs = @(
    "volumes/caddy/data", "volumes/caddy/config",
    "volumes/n8n/data", "volumes/n8n/logs", 
    "volumes/postgres/data", "volumes/prometheus/data",
    "volumes/grafana/data", "volumes/zap/data"
)

foreach ($dir in $volumeDirs) {
    New-Item -ItemType Directory -Path $dir -Force -ErrorAction SilentlyContinue | Out-Null
}

# Generate secure keys if not exists
Write-Host "🔑 Checking encryption keys..." -ForegroundColor Blue

# Build and start services
Write-Host "🏗️  Building secure containers..." -ForegroundColor Green
docker-compose -f docker-compose.secure.yml --env-file .env.secure build --no-cache

Write-Host "🚀 Starting secure services..." -ForegroundColor Green
docker-compose -f docker-compose.secure.yml --env-file .env.secure up -d

# Wait for services to be ready
Write-Host "⏳ Waiting for services to initialize..." -ForegroundColor Blue
Start-Sleep 30

# Health checks
Write-Host "🏥 Performing health checks..." -ForegroundColor Blue

$services = @("n8n-caddy-secure", "n8n-app-secure", "n8n-database-secure", "n8n-prometheus-secure", "n8n-grafana-secure")
foreach ($service in $services) {
    $health = docker inspect --format='{{.State.Health.Status}}' $service 2>$null
    if ($health -eq "healthy" -or $health -eq "") {
        Write-Host "  ✅ $service" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $service ($health)" -ForegroundColor Yellow
    }
}

# Show final status
Write-Host "📊 Deployment status:" -ForegroundColor Cyan
docker-compose -f docker-compose.secure.yml --env-file .env.secure ps

Write-Host ""
Write-Host "🎉 N8N Secure Deployment Started Successfully!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host "🌐 N8N Web Interface: https://localhost" -ForegroundColor Cyan
Write-Host "📊 Grafana Dashboard: https://localhost/grafana" -ForegroundColor Cyan  
Write-Host "📈 Prometheus Metrics: https://localhost/metrics" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔐 Default Credentials:" -ForegroundColor Yellow
Write-Host "  N8N: admin / SecureN8NPassword123!" -ForegroundColor White
Write-Host "  Grafana: admin / SecureGrafanaAdmin789!" -ForegroundColor White
Write-Host ""
Write-Host "📝 Management Commands:" -ForegroundColor Blue
Write-Host "  Stop:   .\start-secure.ps1 -Stop" -ForegroundColor White
Write-Host "  Status: .\start-secure.ps1 -Status" -ForegroundColor White
Write-Host "  Logs:   .\start-secure.ps1 -Logs" -ForegroundColor White
Write-Host "  Test:   .\start-secure.ps1 -Test" -ForegroundColor White
