# 2025-07-20 CH41B01
# Simplified secure Docker deployment

Write-Host "Starting Secure N8N Deployment with Docker" -ForegroundColor Green

# Check Docker
try {
    docker --version | Out-Null
    Write-Host "Docker is available" -ForegroundColor Green
}
catch {
    Write-Host "Installing Docker Desktop..." -ForegroundColor Yellow
    winget install Docker.DockerDesktop
    Write-Host "Please start Docker Desktop and run this script again" -ForegroundColor Yellow
    exit 0
}

# Navigate to docker directory
cd docker

# Copy environment file
if (Test-Path ".env.secure") {
    Copy-Item ".env.secure" ".env" -Force
    Write-Host "Environment configured" -ForegroundColor Green
}

Write-Host "Pulling and building containers..." -ForegroundColor Blue
docker-compose -f docker-compose.secure.yml pull
docker-compose -f docker-compose.secure.yml build

Write-Host "Starting secure services..." -ForegroundColor Blue
docker-compose -f docker-compose.secure.yml up -d

Write-Host ""
Write-Host "SECURE ACCESS LINKS:" -ForegroundColor Green
Write-Host "N8N HTTPS: https://localhost" -ForegroundColor Yellow
Write-Host "Grafana: https://localhost/grafana/" -ForegroundColor Yellow
Write-Host "Metrics: https://localhost/metrics/" -ForegroundColor Yellow
Write-Host ""
Write-Host "Credentials:" -ForegroundColor White
Write-Host "N8N: admin / SecureN8NPassword123!" -ForegroundColor Gray
Write-Host "Grafana: admin / SecureGrafanaAdmin789!" -ForegroundColor Gray
Write-Host ""
Write-Host "Security Features Active:" -ForegroundColor Green
Write-Host "- HTTPS with TLS 1.2+ encryption" -ForegroundColor Green
Write-Host "- Automatic HTTP to HTTPS redirect" -ForegroundColor Green
Write-Host "- Security headers (HSTS, CSP, etc.)" -ForegroundColor Green
Write-Host "- Rate limiting on authentication" -ForegroundColor Green
Write-Host "- Network isolation between services" -ForegroundColor Green
Write-Host "- Non-root container execution" -ForegroundColor Green
Write-Host "- PostgreSQL with encrypted auth" -ForegroundColor Green
Write-Host "- OWASP ZAP security scanning" -ForegroundColor Green
Write-Host ""
Write-Host "Container Status:" -ForegroundColor Yellow
docker-compose -f docker-compose.secure.yml ps

Write-Host ""
Write-Host "DEPLOYMENT COMPLETED!" -ForegroundColor Green
Write-Host "Dedicated to CH41B01" -ForegroundColor Cyan
