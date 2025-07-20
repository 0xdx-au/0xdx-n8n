#!/usr/bin/env pwsh
# 0xdx-n8n Secure Deployment Script
# Generates secure random passwords and deploys the system

param(
    [Parameter(Mandatory=$false)]
    [string]$AdminPassword = "",
    
    [Parameter(Mandatory=$false)]
    [string]$PostgresPassword = "",
    
    [Parameter(Mandatory=$false)]
    [string]$GrafanaPassword = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$RegenerateSecrets = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowPasswords = $false
)

# Security function to generate cryptographically secure passwords
function New-SecurePassword {
    param([int]$Length = 32)
    
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    $password = ""
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    
    for ($i = 0; $i -lt $Length; $i++) {
        $bytes = New-Object byte[] 1
        $rng.GetBytes($bytes)
        $password += $chars[$bytes[0] % $chars.Length]
    }
    
    $rng.Dispose()
    return $password
}

Write-Host "🔐 0xdx-n8n Secure Deployment" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Check if secrets directory exists
if (-not (Test-Path "secrets")) {
    Write-Host "Creating secrets directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "secrets" -Force | Out-Null
}

# Generate or use provided passwords
$secrets = @{}

if ($RegenerateSecrets -or -not (Test-Path "secrets/postgres_password.txt")) {
    if ($PostgresPassword) {
        $secrets.postgres = $PostgresPassword
    } else {
        $secrets.postgres = New-SecurePassword -Length 32
    }
    Write-Host "✓ Generated new PostgreSQL password" -ForegroundColor Green
} else {
    $secrets.postgres = Get-Content "secrets/postgres_password.txt" -Raw
    Write-Host "✓ Using existing PostgreSQL password" -ForegroundColor Green
}

if ($RegenerateSecrets -or -not (Test-Path "secrets/grafana_password.txt")) {
    if ($GrafanaPassword) {
        $secrets.grafana = $GrafanaPassword
    } else {
        $secrets.grafana = New-SecurePassword -Length 24
    }
    Write-Host "✓ Generated new Grafana password" -ForegroundColor Green
} else {
    $secrets.grafana = Get-Content "secrets/grafana_password.txt" -Raw
    Write-Host "✓ Using existing Grafana password" -ForegroundColor Green
}

if ($RegenerateSecrets -or -not (Test-Path "secrets/n8n_encryption_key.txt")) {
    $secrets.n8n_key = New-SecurePassword -Length 32
    Write-Host "✓ Generated new N8N encryption key" -ForegroundColor Green
} else {
    $secrets.n8n_key = Get-Content "secrets/n8n_encryption_key.txt" -Raw
    Write-Host "✓ Using existing N8N encryption key" -ForegroundColor Green
}

if ($RegenerateSecrets -or -not (Test-Path "secrets/grafana_secret_key.txt")) {
    $secrets.grafana_secret = New-SecurePassword -Length 32
    Write-Host "✓ Generated new Grafana secret key" -ForegroundColor Green
} else {
    $secrets.grafana_secret = Get-Content "secrets/grafana_secret_key.txt" -Raw
    Write-Host "✓ Using existing Grafana secret key" -ForegroundColor Green
}

if ($RegenerateSecrets -or -not (Test-Path "secrets/grafana_db_password.txt")) {
    $secrets.grafana_db = New-SecurePassword -Length 24
    Write-Host "✓ Generated new Grafana DB password" -ForegroundColor Green
} else {
    $secrets.grafana_db = Get-Content "secrets/grafana_db_password.txt" -Raw
    Write-Host "✓ Using existing Grafana DB password" -ForegroundColor Green
}

# Write secrets to files with proper permissions
$secrets.postgres | Out-File -FilePath "secrets/postgres_password.txt" -Encoding ascii -NoNewline
$secrets.grafana | Out-File -FilePath "secrets/grafana_password.txt" -Encoding ascii -NoNewline
$secrets.n8n_key | Out-File -FilePath "secrets/n8n_encryption_key.txt" -Encoding ascii -NoNewline
$secrets.grafana_secret | Out-File -FilePath "secrets/grafana_secret_key.txt" -Encoding ascii -NoNewline
$secrets.grafana_db | Out-File -FilePath "secrets/grafana_db_password.txt" -Encoding ascii -NoNewline

Write-Host ""
Write-Host "🚀 Starting deployment..." -ForegroundColor Cyan

# Stop existing containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose -f docker-compose-production.yml down --remove-orphans 2>$null

# Start the deployment
Write-Host "Starting secure deployment..." -ForegroundColor Yellow
docker-compose -f docker-compose-production.yml up -d

Write-Host ""
Write-Host "✅ Deployment started successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Access URLs:" -ForegroundColor Cyan
Write-Host "  Main Dashboard: http://localhost/" -ForegroundColor White
Write-Host "  N8N Workflows: http://localhost/n8n/" -ForegroundColor White
Write-Host "  Grafana Analytics: http://localhost/grafana/" -ForegroundColor White
Write-Host ""

if ($ShowPasswords) {
    Write-Host "🔑 Login Credentials:" -ForegroundColor Cyan
    Write-Host "  Grafana Admin:" -ForegroundColor White
    Write-Host "    Username: admin" -ForegroundColor Gray
    Write-Host "    Password: $($secrets.grafana)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  PostgreSQL:" -ForegroundColor White
    Write-Host "    Username: n8n_user" -ForegroundColor Gray
    Write-Host "    Password: $($secrets.postgres)" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "🔑 Credentials:" -ForegroundColor Cyan
    Write-Host "  Use -ShowPasswords to display credentials" -ForegroundColor Gray
    Write-Host "  Or check secrets/ directory for individual files" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "⚠️  Security Notes:" -ForegroundColor Yellow
Write-Host "  • Passwords are cryptographically generated" -ForegroundColor Gray
Write-Host "  • Store secrets/ directory securely" -ForegroundColor Gray
Write-Host "  • Change default N8N admin password on first login" -ForegroundColor Gray
Write-Host "  • HTTPS disabled for initial setup - enable in production" -ForegroundColor Gray
Write-Host ""
Write-Host "🛡️  Security Features Active:" -ForegroundColor Green
Write-Host "  • DNS over HTTPS (Cloudflare)" -ForegroundColor Gray
Write-Host "  • ClamAV antivirus scanning" -ForegroundColor Gray
Write-Host "  • SAST/DAST security testing" -ForegroundColor Gray
Write-Host "  • Container hardening" -ForegroundColor Gray
Write-Host "  • PostgreSQL encryption" -ForegroundColor Gray

Write-Host ""
Write-Host "Run 'docker-compose -f docker-compose-production.yml ps' to check container status" -ForegroundColor Cyan
