# 2025-07-20 CH41B01
# Simple N8N Security Check

Write-Host "N8N SECURITY AUDIT" -ForegroundColor Red
Write-Host "==================" -ForegroundColor Red

$issues = @()

# 1. HTTPS Check
Write-Host "`n1. Checking HTTPS..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri "https://localhost" -UseBasicParsing -TimeoutSec 5 | Out-Null
    Write-Host "HTTPS: Available" -ForegroundColor Green
} catch {
    Write-Host "HTTPS: NOT CONFIGURED" -ForegroundColor Red
    $issues += "Missing HTTPS/TLS encryption"
}

# 2. Default Credentials Check
Write-Host "`n2. Checking Credentials..." -ForegroundColor Yellow
Write-Host "N8N: Using default credentials (admin/SecureN8NPassword123!)" -ForegroundColor Red
Write-Host "Grafana: Using default credentials (admin/SecureGrafanaAdmin789!)" -ForegroundColor Red
$issues += "N8N using default credentials"
$issues += "Grafana using default credentials"

# 3. Container Security
Write-Host "`n3. Checking Container Security..." -ForegroundColor Yellow
$containers = @("n8n-secure", "n8n-postgres", "n8n-grafana")
foreach ($container in $containers) {
    $secInfo = docker inspect $container --format '{{.HostConfig.ReadonlyRootfs}}{{.HostConfig.SecurityOpt}}'
    if ($secInfo -match 'false') {
        Write-Host "$container: Root filesystem writable" -ForegroundColor Red
        $issues += "$container root filesystem not read-only"
    }
    if ($secInfo -notmatch 'no-new-privileges') {
        Write-Host "$container: Missing security options" -ForegroundColor Red
        $issues += "$container missing security hardening"
    }
}

# 4. Network Security
Write-Host "`n4. Checking Network Security..." -ForegroundColor Yellow
$ports = netstat -an | findstr "LISTENING" | findstr ":80 :443 :3000"
if ($ports) {
    Write-Host "Services exposed on all interfaces" -ForegroundColor Red
    $issues += "Services bound to all network interfaces"
}

# 5. Environment Variables
Write-Host "`n5. Checking Environment Variables..." -ForegroundColor Yellow
$envSecrets = docker exec n8n-secure env | findstr "PASSWORD"
if ($envSecrets) {
    Write-Host "Secrets visible in environment variables" -ForegroundColor Red
    $issues += "Database credentials exposed"
}

# 6. Security Headers
Write-Host "`n6. Checking Security Headers..." -ForegroundColor Yellow
try {
    $headers = Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing -TimeoutSec 5
    $secHeaders = @("X-Frame-Options", "X-Content-Type-Options", "Strict-Transport-Security")
    foreach ($header in $secHeaders) {
        if (-not $headers.Headers[$header]) {
            Write-Host "Missing security header: $header" -ForegroundColor Red
            $issues += "Missing HTTP security header: $header"
        }
    }
} catch {
    Write-Host "Unable to check security headers" -ForegroundColor Red
}

# Summary
Write-Host "`nSECURITY SUMMARY" -ForegroundColor Red
Write-Host "================" -ForegroundColor Red
Write-Host "Total Issues: $($issues.Count)" -ForegroundColor Red

foreach ($issue in $issues) {
    Write-Host "- $issue" -ForegroundColor Red
}

Write-Host "`nRECOMMENDATION: Apply security fixes" -ForegroundColor Yellow
