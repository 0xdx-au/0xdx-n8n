# 2025-07-20 CH41B01
param(
    [int]$Port = 5678
)

Write-Host "Starting Direct N8N Installation" -ForegroundColor Green

function Test-NodeJS {
    try {
        $nodeVersion = node --version
        Write-Host "Node.js found: $nodeVersion" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Node.js not found. Please install from https://nodejs.org" -ForegroundColor Yellow
        return $false
    }
}

function Install-N8N {
    Write-Host "Installing N8N..." -ForegroundColor Blue
    try {
        npx --version | Out-Null
        Write-Host "NPX available, N8N will be installed on first run" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "NPM/NPX not available"
        return $false
    }
}

function Setup-Environment {
    Write-Host "Setting up environment..." -ForegroundColor Blue
    
    $dataPath = "W:\DEV\0xdx-n8n\data"
    $logsPath = "W:\DEV\0xdx-n8n\logs"
    
    New-Item -ItemType Directory -Path $dataPath -Force | Out-Null
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
    
    $env:N8N_USER_FOLDER = $dataPath
    $env:N8N_PORT = $Port
    $env:N8N_HOST = "localhost"
    $env:N8N_PROTOCOL = "http"
    $env:N8N_LOG_LEVEL = "info"
    $env:N8N_ENCRYPTION_KEY = "n8n-test-key-123456789012345678901234"
    
    Write-Host "Environment configured" -ForegroundColor Green
    Write-Host "Data: $dataPath" -ForegroundColor Gray
    Write-Host "Port: $Port" -ForegroundColor Gray
}

function Start-N8N {
    Write-Host "Starting N8N server..." -ForegroundColor Green
    Write-Host "Access: http://localhost:$Port" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host "---" -ForegroundColor Gray
    
    npx n8n
}

# Main execution
if (-not (Test-NodeJS)) {
    exit 1
}

if (-not (Install-N8N)) {
    exit 1
}

Setup-Environment

Write-Host ""
Write-Host "ACCESS LINK: http://localhost:$Port" -ForegroundColor Yellow
Write-Host "Repository: W:\DEV\0xdx-n8n" -ForegroundColor Yellow
Write-Host ""
Write-Host "Starting N8N Server..." -ForegroundColor Green
Write-Host "Dedicated to CH41B01" -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Gray

Start-N8N
