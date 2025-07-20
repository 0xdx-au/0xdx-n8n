# 2025-07-20 CH41B01
# N8N Security Audit Script

Write-Host "========================================" -ForegroundColor Red
Write-Host "N8N DEPLOYMENT SECURITY AUDIT" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red

$issues = @()

# 1. Check for HTTPS/TLS Configuration
Write-Host "`n1. CHECKING TLS/HTTPS CONFIGURATION..." -ForegroundColor Yellow
try {
    $httpsTest = Invoke-WebRequest -Uri "https://localhost" -UseBasicParsing -TimeoutSec 5 2>$null
    Write-Host "✅ HTTPS: Available" -ForegroundColor Green
} catch {
    Write-Host "❌ HTTPS: NOT CONFIGURED" -ForegroundColor Red
    $issues += "Missing HTTPS/TLS encryption"
}

# 2. Check for Default Credentials
Write-Host "`n2. CHECKING FOR DEFAULT CREDENTIALS..." -ForegroundColor Yellow
$defaultCreds = @(
    @{Service="N8N"; User="admin"; Pass="SecureN8NPassword123!"},
    @{Service="Grafana"; User="admin"; Pass="SecureGrafanaAdmin789!"}
)

foreach ($cred in $defaultCreds) {
    Write-Host "❌ $($cred.Service): Using predictable credentials ($($cred.User)/$($cred.Pass))" -ForegroundColor Red
    $issues += "$($cred.Service) using weak/predictable credentials"
}

# 3. Check Container Security Settings
Write-Host "`n3. CHECKING CONTAINER SECURITY..." -ForegroundColor Yellow

$containers = @("n8n-secure", "n8n-postgres", "n8n-grafana")
foreach ($container in $containers) {
    $secInfo = docker inspect $container --format '{{json .HostConfig.Privileged}}{{json .HostConfig.ReadonlyRootfs}}{{json .Config.User}}{{json .HostConfig.SecurityOpt}}'
    
    if ($secInfo -match 'true.*false') {
        Write-Host "❌ ${container}: Running with elevated privileges" -ForegroundColor Red
        $issues += "${container} running with elevated privileges"
    }
    
    if ($secInfo -match 'false.*false') {
        Write-Host "❌ ${container}: Root filesystem is writable" -ForegroundColor Red
        $issues += "${container} root filesystem not read-only"
    }
    
    if ($secInfo -match '"".*\[\]') {
        Write-Host "❌ ${container}: No user specified (running as root)" -ForegroundColor Red
        $issues += "${container} running as root user"
    }
    
    if ($secInfo -notmatch 'no-new-privileges') {
        Write-Host "❌ ${container}: Missing no-new-privileges security option" -ForegroundColor Red
        $issues += "${container} missing no-new-privileges"
    }
}

# 4. Check Network Exposure
Write-Host "`n4. CHECKING NETWORK EXPOSURE..." -ForegroundColor Yellow
$exposedPorts = netstat -an | findstr "LISTENING" | findstr ":80 :443 :3000"
if ($exposedPorts) {
    Write-Host "❌ Services exposed on all interfaces (0.0.0.0)" -ForegroundColor Red
    $issues += "Services bound to all network interfaces"
}

# 5. Check for Secrets in Environment Variables
Write-Host "`n5. CHECKING FOR EXPOSED SECRETS..." -ForegroundColor Yellow
$envSecrets = docker exec n8n-secure env | findstr "PASSWORD\|KEY\|SECRET\|TOKEN"
if ($envSecrets) {
    Write-Host "❌ Secrets visible in environment variables" -ForegroundColor Red
    $issues += "Database credentials exposed in environment variables"
}

# 6. Check File Permissions
Write-Host "`n6. CHECKING FILE PERMISSIONS..." -ForegroundColor Yellow
$filePerms = docker exec n8n-secure find /home/node/.n8n -type f -perm +066 2>$null
if ($filePerms) {
    Write-Host "❌ Sensitive files with overly permissive permissions" -ForegroundColor Red
    $issues += "Sensitive configuration files with weak permissions"
}

# 7. Check for Rate Limiting
Write-Host "`n7. CHECKING RATE LIMITING..." -ForegroundColor Yellow
Write-Host "❌ No rate limiting configured" -ForegroundColor Red
$issues += "Missing rate limiting protection"

# 8. Check for Security Headers
Write-Host "`n8. CHECKING HTTP SECURITY HEADERS..." -ForegroundColor Yellow
try {
    $headers = Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing -TimeoutSec 5
    $secHeaders = @("X-Frame-Options", "X-Content-Type-Options", "Strict-Transport-Security", "Content-Security-Policy")
    
    foreach ($header in $secHeaders) {
        if (-not $headers.Headers[$header]) {
            Write-Host "❌ Missing security header: $header" -ForegroundColor Red
            $issues += "Missing HTTP security header: $header"
        }
    }
} catch {
    Write-Host "❌ Unable to check security headers" -ForegroundColor Red
}

# 9. Check for Logging Configuration
Write-Host "`n9. CHECKING LOGGING CONFIGURATION..." -ForegroundColor Yellow
$logConfig = docker exec n8n-secure ls -la /var/log/n8n/ 2>$null
if (-not $logConfig) {
    Write-Host "❌ No centralized logging configured" -ForegroundColor Red
    $issues += "Missing centralized logging"
}

# 10. Check Database Security
Write-Host "`n10. CHECKING DATABASE SECURITY..." -ForegroundColor Yellow
$pgVersion = docker exec n8n-postgres postgres --version
Write-Host "ℹ️  PostgreSQL Version: $pgVersion" -ForegroundColor Blue

# Summary
Write-Host "`n========================================" -ForegroundColor Red
Write-Host "SECURITY AUDIT SUMMARY" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host "Total Security Issues Found: $($issues.Count)" -ForegroundColor Red

$criticalIssues = 0
foreach ($issue in $issues) {
    Write-Host "❌ $issue" -ForegroundColor Red
    if ($issue -match "root|privilege|credential|HTTPS") {
        $criticalIssues++
    }
}

Write-Host "`nCritical Issues: $criticalIssues" -ForegroundColor Red
Write-Host "Total Issues: $($issues.Count)" -ForegroundColor Red

if ($issues.Count -gt 0) {
    Write-Host "`n⚠️  RECOMMENDATION: Apply security hardening before production use!" -ForegroundColor Yellow
} else {
    Write-Host "`nNo major security issues found!" -ForegroundColor Green
}
