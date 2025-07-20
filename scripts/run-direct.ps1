# 2025-07-20 CH41B01
# Direct N8N installation and run without Docker

param(
    [int]$Port = 5678,
    [string]$Environment = "development"
)

Write-Host "🚀 Starting Direct N8N Installation and Deployment" -ForegroundColor Green
Write-Host "Port: $Port | Environment: $Environment" -ForegroundColor Yellow

function Test-NodeJS {
    Write-Host "Checking Node.js installation..." -ForegroundColor Blue
    
    try {
        $nodeVersion = node --version
        Write-Host "✅ Node.js found: $nodeVersion" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Node.js not found. Installing Node.js..." -ForegroundColor Yellow
        
        # Check for winget
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Installing Node.js via winget..." -ForegroundColor Blue
            winget install OpenJS.NodeJS
            
            # Refresh PATH
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            
            Start-Sleep 5
            try {
                $nodeVersion = node --version
                Write-Host "✅ Node.js installed: $nodeVersion" -ForegroundColor Green
                return $true
            }
            catch {
                Write-Warning "Node.js installation may require system restart. Please restart PowerShell."
                return $false
            }
        }
        else {
            Write-Host "Please install Node.js manually from: https://nodejs.org" -ForegroundColor Yellow
            return $false
        }
    }
}

function Install-N8N {
    Write-Host "Installing N8N globally..." -ForegroundColor Blue
    
    try {
        # Check if n8n is already installed
        $n8nVersion = npx n8n --version 2>$null
        if ($n8nVersion) {
            Write-Host "✅ N8N already installed: $n8nVersion" -ForegroundColor Green
            return $true
        }
    }
    catch {}
    
    try {
        Write-Host "Installing N8N via npm..." -ForegroundColor Blue
        npm install -g n8n
        Write-Host "✅ N8N installed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "Global install failed. Trying local install..."
        try {
            npm install n8n
            Write-Host "✅ N8N installed locally" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Error "Failed to install N8N: $($_.Exception.Message)"
            return $false
        }
    }
}

function Setup-Environment {
    Write-Host "Setting up N8N environment..." -ForegroundColor Blue
    
    # Create data directories
    $dataPath = "W:\DEV\0xdx-n8n\data"
    $logsPath = "W:\DEV\0xdx-n8n\logs"
    
    New-Item -ItemType Directory -Path $dataPath -Force | Out-Null
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
    New-Item -ItemType Directory -Path "$dataPath\workflows" -Force | Out-Null
    New-Item -ItemType Directory -Path "$dataPath\credentials" -Force | Out-Null
    
    # Set environment variables
    $env:N8N_USER_FOLDER = $dataPath
    $env:N8N_PORT = $Port
    $env:N8N_HOST = "localhost"
    $env:N8N_PROTOCOL = "http"
    $env:N8N_LOG_LEVEL = "info"
    $env:N8N_BASIC_AUTH_ACTIVE = "false"
    $env:N8N_ENCRYPTION_KEY = "n8n-test-encryption-key-123456789"
    $env:WEBHOOK_URL = "http://localhost:$Port"
    
    Write-Host "✅ Environment configured" -ForegroundColor Green
    Write-Host "Data folder: $dataPath" -ForegroundColor Gray
    Write-Host "Logs folder: $logsPath" -ForegroundColor Gray
}

function Start-N8N {
    Write-Host "🎯 Starting N8N server..." -ForegroundColor Green
    Write-Host "This will start N8N on http://localhost:$Port" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
    Write-Host "---" -ForegroundColor Gray
    
    try {
        # Try global n8n first
        if (Get-Command n8n -ErrorAction SilentlyContinue) {
            n8n start
        }
        # Try npx if global not available
        elseif (Get-Command npx -ErrorAction SilentlyContinue) {
            npx n8n start
        }
        # Try local installation
        elseif (Test-Path "node_modules\.bin\n8n.cmd") {
            .\node_modules\.bin\n8n.cmd start
        }
        else {
            Write-Error "N8N executable not found. Please check installation."
        }
    }
    catch {
        Write-Error "Failed to start N8N: $($_.Exception.Message)"
    }
}

function Show-Links {
    Write-Host "`n🔗 ACCESS LINKS:" -ForegroundColor Green
    Write-Host "N8N Web Interface: http://localhost:$Port" -ForegroundColor Yellow
    Write-Host "Repository: W:\DEV\0xdx-n8n" -ForegroundColor Yellow
    Write-Host "`nPress Ctrl+C to stop N8N when running" -ForegroundColor Gray
}

# Main execution
try {
    if (-not (Test-NodeJS)) {
        Write-Host "❌ Node.js installation required. Exiting..." -ForegroundColor Red
        exit 1
    }
    
    if (-not (Install-N8N)) {
        Write-Host "❌ N8N installation failed. Exiting..." -ForegroundColor Red
        exit 1
    }
    
    Setup-Environment
    Show-Links
    
    Write-Host "`n🚀 STARTING N8N SERVER..." -ForegroundColor Green
    Write-Host "Dedicated to CH41B01" -ForegroundColor Cyan
    Write-Host "---" -ForegroundColor Gray
    
    Start-N8N
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}
