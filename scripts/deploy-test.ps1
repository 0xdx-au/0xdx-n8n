# 2025-07-20 CH41B01
# Quick deployment for testing without admin requirements
param(
    [string]$Environment = "development",
    [string]$SecurityLevel = "basic",
    [string]$DataPath = "W:\DEV\0xdx-n8n\data",
    [string]$LogPath = "W:\DEV\0xdx-n8n\logs",
    [int]$Port = 5678
)

Write-Host "Starting 0xdx-n8n Test Deployment" -ForegroundColor Green
Write-Host "Environment: $Environment | Security Level: $SecurityLevel" -ForegroundColor Yellow

function Initialize-TestDirectories {
    Write-Host "Creating test directories..." -ForegroundColor Blue
    $directories = @($DataPath, $LogPath, "$DataPath\workflows", "$DataPath\credentials")
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "Created: $dir" -ForegroundColor Gray
        }
    }
}

function Generate-TestConfig {
    Write-Host "Generating test configuration..." -ForegroundColor Blue
    
    $config = @{
        N8N_ENCRYPTION_KEY = "TESTKEY123456789012345678901234"
        N8N_USER_FOLDER = $DataPath
        N8N_LOG_LEVEL = "info"
        N8N_LOG_OUTPUT = "console"
        N8N_SECURE_COOKIE = "false"
        N8N_BASIC_AUTH_ACTIVE = "false"
        N8N_DISABLE_UI = "false"
        WEBHOOK_URL = "http://localhost:$Port"
        N8N_PROTOCOL = "http"
        NODE_ENV = $Environment
        N8N_PORT = $Port
    }
    
    $envFile = "configs\n8n\.env.$Environment"
    if (-not (Test-Path (Split-Path $envFile))) {
        New-Item -ItemType Directory -Path (Split-Path $envFile) -Force
    }
    
    $config.GetEnumerator() | ForEach-Object {
        "$($_.Key)=$($_.Value)"
    } | Out-File -FilePath $envFile -Encoding UTF8
    
    Write-Host "Configuration saved to $envFile" -ForegroundColor Green
    return $config
}

function Create-DockerCompose {
    param($Config)
    
    Write-Host "Creating Docker Compose configuration..." -ForegroundColor Blue
    
    $dockerCompose = @"
version: '3.8'
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n-test
    restart: unless-stopped
    ports:
      - "$Port`:5678"
    environment:
"@
    
    $Config.GetEnumerator() | ForEach-Object {
        $dockerCompose += "`n      - $($_.Key)=$($_.Value)"
    }
    
    $dockerCompose += @"

    volumes:
      - $DataPath`:/home/node/.n8n
      - $LogPath`:/var/log/n8n
    networks:
      - n8n-test-net

networks:
  n8n-test-net:
    driver: bridge
"@
    
    $dockerCompose | Out-File -FilePath "docker\docker-compose-test.yml" -Encoding UTF8
    Write-Host "Docker Compose configuration created" -ForegroundColor Green
}

function Start-TestDeployment {
    Write-Host "Starting test deployment..." -ForegroundColor Blue
    
    Push-Location "docker"
    try {
        if (Get-Command docker -ErrorAction SilentlyContinue) {
            docker-compose -f docker-compose-test.yml down --remove-orphans 2>$null
            docker-compose -f docker-compose-test.yml up -d
            Write-Host "N8N container started successfully!" -ForegroundColor Green
        } else {
            Write-Warning "Docker not available. Configuration files created for manual deployment."
        }
    }
    catch {
        Write-Warning "Docker deployment failed: $($_.Exception.Message)"
        Write-Host "You can manually run: docker-compose -f docker-compose-test.yml up -d" -ForegroundColor Yellow
    }
    finally {
        Pop-Location
    }
}

function Show-AccessLinks {
    Write-Host "`n=== ACCESS LINKS ===" -ForegroundColor Green
    Write-Host "N8N Web Interface: http://localhost:$Port" -ForegroundColor Yellow
    Write-Host "Repository Location: W:\DEV\0xdx-n8n" -ForegroundColor Yellow
    Write-Host "`nConfiguration Files:" -ForegroundColor White
    Write-Host "- Environment Config: configs\n8n\.env.$Environment" -ForegroundColor Gray
    Write-Host "- Docker Compose: docker\docker-compose-test.yml" -ForegroundColor Gray
    Write-Host "- Data Directory: $DataPath" -ForegroundColor Gray
    Write-Host "- Logs Directory: $LogPath" -ForegroundColor Gray
}

try {
    Initialize-TestDirectories
    $config = Generate-TestConfig
    Create-DockerCompose -Config $config
    Start-TestDeployment
    Show-AccessLinks
    
    Write-Host "`n*** Test Deployment Complete! ***" -ForegroundColor Green
    Write-Host "Dedicated to CH41B01" -ForegroundColor Cyan
}
catch {
    Write-Error "Test deployment failed: $($_.Exception.Message)"
}
