# 2025-07-20 CH41B01
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("basic", "enhanced", "high")]
    [string]$SecurityLevel,
    
    [string]$DataPath = "C:\N8N\data",
    [string]$LogPath = "C:\N8N\logs",
    [int]$Port = 5678,
    [bool]$EnableMonitoring = $true,
    [bool]$EnableZAP = $true
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "Starting 0xdx-n8n Secure Deployment for Windows" -ForegroundColor Green
Write-Host "Environment: $Environment | Security Level: $SecurityLevel" -ForegroundColor Yellow

function Test-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Blue
    
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator"
    }
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "Docker not found. Attempting to install Docker Desktop..." -ForegroundColor Yellow
        
        # Check if winget is available
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Installing Docker Desktop via winget..." -ForegroundColor Blue
            winget install Docker.DockerDesktop
        } else {
            Write-Host "Downloading Docker Desktop installer..." -ForegroundColor Blue
            $dockerUrl = "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
            $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
            
            Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller
            Write-Host "Installing Docker Desktop..." -ForegroundColor Blue
            Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet" -Wait
            Remove-Item $dockerInstaller -Force
        }
        
        Write-Host "Docker Desktop installed. Please start Docker Desktop manually and run this script again." -ForegroundColor Yellow
        Write-Host "After Docker Desktop starts, you may need to restart your PowerShell session." -ForegroundColor Yellow
        exit 0
    }
    
    try {
        docker info | Out-Null
        Write-Host "Docker daemon is running" -ForegroundColor Green
    }
    catch {
        Write-Host "Docker daemon is not running. Starting Docker Desktop..." -ForegroundColor Yellow
        
        $dockerDesktop = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
        if (-not $dockerDesktop) {
            $dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
            if (Test-Path $dockerPath) {
                Start-Process -FilePath $dockerPath
                Write-Host "Waiting for Docker Desktop to start..." -ForegroundColor Yellow
                
                $maxWait = 120
                $waited = 0
                do {
                    Start-Sleep 5
                    $waited += 5
                    try {
                        docker info | Out-Null
                        break
                    } catch { }
                } while ($waited -lt $maxWait)
                
                if ($waited -ge $maxWait) {
                    Write-Error "Docker Desktop failed to start within 2 minutes. Please start it manually and run the script again."
                }
            } else {
                Write-Error "Docker Desktop not found. Please install Docker Desktop and run the script again."
            }
        }
    }
    
    Write-Host "Prerequisites check passed" -ForegroundColor Green
}

function Initialize-Directories {
    Write-Host "Initializing secure directories..." -ForegroundColor Blue
    
    $directories = @($DataPath, $LogPath, "$DataPath\workflows", "$DataPath\credentials")
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "Created directory: $dir" -ForegroundColor Gray
        }
    }
    
    icacls $DataPath /grant "SYSTEM:(OI)(CI)F" /grant "Administrators:(OI)(CI)F" /remove "Users" /T | Out-Null
    icacls $LogPath /grant "SYSTEM:(OI)(CI)F" /grant "Administrators:(OI)(CI)F" /remove "Users" /T | Out-Null
    
    Write-Host "Directory permissions secured" -ForegroundColor Green
}

function Set-FirewallRules {
    param([int]$Port)
    
    Write-Host "Configuring Windows Firewall..." -ForegroundColor Blue
    
    $ruleName = "N8N-Secure-$Port"
    
    try {
        Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    }
    catch {}
    
    if ($SecurityLevel -eq "high") {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -Profile Domain,Private -RemoteAddress LocalSubnet
        Write-Host "Firewall rule created for local subnet only" -ForegroundColor Green
    }
    else {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -Profile Domain,Private
        Write-Host "Firewall rule created for private networks" -ForegroundColor Green
    }
}

function Generate-SecureConfig {
    Write-Host "Generating secure configuration..." -ForegroundColor Blue
    
    $encryptionKey = -join ((1..32) | ForEach { [char](Get-Random -Min 65 -Max 90) })
    $jwtSecret = -join ((1..64) | ForEach { [char](Get-Random -Min 33 -Max 126) })
    
    $config = @{
        N8N_ENCRYPTION_KEY = $encryptionKey
        N8N_USER_FOLDER = $DataPath
        N8N_LOG_LEVEL = if ($Environment -eq "production") { "warn" } else { "info" }
        N8N_LOG_OUTPUT = "file"
        N8N_LOG_FILE_LOCATION = "$LogPath\n8n.log"
        N8N_SECURE_COOKIE = "true"
        N8N_JWT_AUTH_HEADER = "true"
        N8N_JWT_AUTH_HEADER_VALUE_PREFIX = "Bearer"
        N8N_BASIC_AUTH_ACTIVE = "true"
        N8N_DISABLE_UI = if ($SecurityLevel -eq "high") { "true" } else { "false" }
        WEBHOOK_URL = "https://localhost:$Port"
        N8N_PROTOCOL = "https"
        N8N_SSL_CERT = "/certs/server.crt"
        N8N_SSL_KEY = "/certs/server.key"
        NODE_ENV = $Environment
    }
    
    $envFile = "$PSScriptRoot\..\configs\n8n\.env.$Environment"
    
    $config.GetEnumerator() | ForEach-Object {
        "$($_.Key)=$($_.Value)"
    } | Out-File -FilePath $envFile -Encoding UTF8
    
    Write-Host "Configuration saved to $envFile" -ForegroundColor Green
    return $config
}

function Generate-TLSCertificates {
    Write-Host "Generating TLS certificates..." -ForegroundColor Blue
    
    $certPath = "$PSScriptRoot\..\docker\security\certs"
    if (-not (Test-Path $certPath)) {
        New-Item -ItemType Directory -Path $certPath -Force | Out-Null
    }
    
    $opensslConfig = @"
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = AU
ST = State
L = City
O = Organization
CN = localhost

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = 127.0.0.1
IP.1 = 127.0.0.1
"@
    
    $opensslConfig | Out-File -FilePath "$certPath\openssl.conf" -Encoding UTF8
    
    docker run --rm -v "$certPath`:/certs" alpine/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /certs/server.key -out /certs/server.crt -config /certs/openssl.conf
    
    Write-Host "TLS certificates generated" -ForegroundColor Green
}

function Deploy-SecurityScanning {
    if (-not $EnableZAP) { return }
    
    Write-Host "Setting up OWASP ZAP security scanning..." -ForegroundColor Blue
    
    $zapConfig = @"
version: '3.8'
services:
  zap:
    image: zaproxy/zap-stable:latest
    container_name: n8n-security-zap
    restart: unless-stopped
    ports:
      - "8090:8090"
    command: zap-baseline.py -t https://host.docker.internal:$Port -J zap-report.json
    volumes:
      - zap-reports:/zap/wrk/reports
    networks:
      - n8n-security-net

volumes:
  zap-reports:

networks:
  n8n-security-net:
    driver: bridge
"@
    
    $zapConfig | Out-File -FilePath "$PSScriptRoot\..\docker\docker-compose.zap.yml" -Encoding UTF8
    Write-Host "ZAP security scanning configured" -ForegroundColor Green
}

function Deploy-Monitoring {
    if (-not $EnableMonitoring) { return }
    
    Write-Host "Setting up Podman monitoring..." -ForegroundColor Blue
    
    $monitoringConfig = @"
version: '3.8'
services:
  podman-gui:
    image: quay.io/cockpit/ws:latest
    container_name: n8n-podman-monitor
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - COCKPIT_FEATURE_DOCKER=true
    networks:
      - n8n-monitor-net

  prometheus:
    image: prom/prometheus:latest
    container_name: n8n-prometheus
    restart: unless-stopped
    ports:
      - "9091:9090"
    volumes:
      - ./configs/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    networks:
      - n8n-monitor-net

  grafana:
    image: grafana/grafana:latest
    container_name: n8n-grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123!
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - n8n-monitor-net

volumes:
  prometheus-data:
  grafana-data:

networks:
  n8n-monitor-net:
    driver: bridge
"@
    
    $monitoringConfig | Out-File -FilePath "$PSScriptRoot\..\docker\docker-compose.monitoring.yml" -Encoding UTF8
    Write-Host "Monitoring stack configured" -ForegroundColor Green
}

function Deploy-N8NContainer {
    param($Config)
    
    Write-Host "Deploying N8N container with security hardening..." -ForegroundColor Blue
    
    $dockerCompose = @"
version: '3.8'
services:
  n8n:
    build:
      context: ./docker
      dockerfile: Dockerfile.secure
    container_name: n8n-secure
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
      - n8n-data:$DataPath
      - n8n-logs:$LogPath
      - ./docker/security/certs:/certs:ro
    user: "1000:1000"
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    networks:
      - n8n-secure-net
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "https://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s

volumes:
  n8n-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: $DataPath
  n8n-logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: $LogPath

networks:
  n8n-secure-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
"@
    
    $dockerCompose | Out-File -FilePath "$PSScriptRoot\..\docker\docker-compose.yml" -Encoding UTF8
    Write-Host "N8N container configuration saved" -ForegroundColor Green
}

function Start-Deployment {
    Write-Host "Starting deployment..." -ForegroundColor Blue
    
    Push-Location "$PSScriptRoot\..\docker"
    
    try {
        docker-compose down --remove-orphans 2>$null
        docker-compose build --no-cache
        docker-compose up -d
        
        if ($EnableMonitoring) {
            docker-compose -f docker-compose.monitoring.yml up -d
        }
        
        if ($EnableZAP) {
            Start-Sleep 30
            docker-compose -f docker-compose.zap.yml up -d
        }
        
        Write-Host "Deployment completed successfully!" -ForegroundColor Green
        Write-Host "N8N is available at: https://localhost:$Port" -ForegroundColor Yellow
        
        if ($EnableMonitoring) {
            Write-Host "Monitoring dashboard: http://localhost:9090" -ForegroundColor Yellow
            Write-Host "Grafana dashboard: http://localhost:3000 (admin/admin123!)" -ForegroundColor Yellow
        }
        
        if ($EnableZAP) {
            Write-Host "Security scanning will complete in background" -ForegroundColor Yellow
        }
    }
    finally {
        Pop-Location
    }
}

function Test-Deployment {
    Write-Host "Testing deployment..." -ForegroundColor Blue
    
    $maxAttempts = 30
    $attempt = 0
    
    do {
        $attempt++
        try {
            $response = Invoke-WebRequest -Uri "https://localhost:$Port/healthz" -UseBasicParsing -SkipCertificateCheck -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Host "Health check passed!" -ForegroundColor Green
                return $true
            }
        }
        catch {
            Write-Host "Attempt $attempt/$maxAttempts - Waiting for N8N to start..." -ForegroundColor Gray
            Start-Sleep 10
        }
    } while ($attempt -lt $maxAttempts)
    
    Write-Warning "Health check failed after $maxAttempts attempts"
    return $false
}

try {
    Test-Prerequisites
    Initialize-Directories
    Set-FirewallRules -Port $Port
    $config = Generate-SecureConfig
    Generate-TLSCertificates
    Deploy-SecurityScanning
    Deploy-Monitoring
    Deploy-N8NContainer -Config $config
    Start-Deployment
    Test-Deployment
    
    Write-Host "`nDeployment Summary:" -ForegroundColor Green
    Write-Host "Environment: $Environment" -ForegroundColor White
    Write-Host "Security Level: $SecurityLevel" -ForegroundColor White
    Write-Host "N8N URL: https://localhost:$Port" -ForegroundColor White
    Write-Host "Data Path: $DataPath" -ForegroundColor White
    Write-Host "Log Path: $LogPath" -ForegroundColor White
    
    if ($EnableMonitoring) {
        Write-Host "Monitoring: Enabled (Port 9090, 3000)" -ForegroundColor White
    }
    
    if ($EnableZAP) {
        Write-Host "Security Scanning: Enabled (Port 8090)" -ForegroundColor White
    }
    
    Write-Host "`n*** Deployment completed successfully! ***" -ForegroundColor Green
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    Write-Host "Check logs for detailed error information" -ForegroundColor Red
    exit 1
}
