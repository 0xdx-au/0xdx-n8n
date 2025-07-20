# 2025-07-20 CH41B01
# Comprehensive Logging Engine Manager for N8N Namespace

param(
    [switch]$Start,
    [switch]$Stop,
    [switch]$Status,
    [switch]$Tail,
    [switch]$Archive,
    [switch]$Clean,
    [string]$Service = "all"
)

Write-Host "N8N LOGGING ENGINE MANAGER" -ForegroundColor Blue
Write-Host "===========================" -ForegroundColor Blue

$logDir = "logs"
$services = @("n8n", "caddy", "postgres", "grafana", "aggregated", "security")

function Show-LogStatus {
    Write-Host "`nLOG STATUS FOR N8N NAMESPACE:" -ForegroundColor Yellow
    Write-Host "=============================" -ForegroundColor Yellow
    
    foreach ($svc in $services) {
        $path = "$logDir/$svc"
        if (Test-Path $path) {
            $files = Get-ChildItem -Path $path -File -Recurse | Measure-Object -Property Length -Sum
            $totalSize = [math]::Round($files.Sum / 1MB, 2)
            Write-Host "📁 $svc`: $($files.Count) files, ${totalSize}MB total" -ForegroundColor Green
            
            # Show recent log files
            Get-ChildItem -Path $path -File | Sort-Object LastWriteTime -Descending | Select-Object -First 3 | ForEach-Object {
                Write-Host "   └── $($_.Name) ($([math]::Round($_.Length / 1KB, 1))KB) - $($_.LastWriteTime)" -ForegroundColor White
            }
        } else {
            Write-Host "📁 $svc`: Directory not found" -ForegroundColor Red
        }
    }
}

function Start-LogCollection {
    Write-Host "`nSTARTING LOG COLLECTION..." -ForegroundColor Green
    
    # Ensure all log directories exist
    foreach ($svc in $services) {
        $path = "$logDir/$svc"
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Host "✅ Created log directory: $path" -ForegroundColor Green
        }
    }
    
    # Start log rotation job
    $rotateJob = Start-Job -ScriptBlock {
        param($logDir)
        while ($true) {
            Get-ChildItem -Path $logDir -File -Recurse | Where-Object { 
                $_.Length -gt 50MB 
            } | ForEach-Object {
                $newName = $_.Name + "." + (Get-Date -Format "yyyyMMdd-HHmmss")
                Rename-Item -Path $_.FullName -NewName $newName
                Write-Host "🔄 Rotated log: $($_.Name)" -ForegroundColor Yellow
            }
            Start-Sleep -Seconds 3600 # Check every hour
        }
    } -ArgumentList $logDir
    
    Write-Host "✅ Log collection started (Job ID: $($rotateJob.Id))" -ForegroundColor Green
}

function Stop-LogCollection {
    Write-Host "`nSTOPPING LOG COLLECTION..." -ForegroundColor Yellow
    
    # Stop any running log jobs
    Get-Job | Where-Object { $_.Name -like "*log*" -or $_.State -eq "Running" } | Stop-Job -PassThru | Remove-Job
    Write-Host "✅ Log collection stopped" -ForegroundColor Green
}

function Show-LiveLogs {
    param([string]$ServiceName)
    
    if ($ServiceName -eq "all") {
        Write-Host "`nSHOWING LIVE LOGS FOR ALL SERVICES..." -ForegroundColor Cyan
        Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
        
        # Show Docker logs for all containers
        docker-compose -f docker-compose-fixed.yml logs -f
    } else {
        $logPath = "$logDir/$ServiceName"
        if (Test-Path $logPath) {
            Write-Host "`nSHOWING LIVE LOGS FOR $ServiceName..." -ForegroundColor Cyan
            $latestLog = Get-ChildItem -Path $logPath -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($latestLog) {
                Get-Content -Path $latestLog.FullName -Tail 50 -Wait
            } else {
                Write-Host "No log files found in $logPath" -ForegroundColor Red
            }
        } else {
            Write-Host "Log directory not found: $logPath" -ForegroundColor Red
        }
    }
}

function Archive-Logs {
    Write-Host "`nARCHIVING OLD LOGS..." -ForegroundColor Yellow
    
    $archiveDate = (Get-Date).AddDays(-7)
    $archiveDir = "$logDir/archive-$(Get-Date -Format 'yyyyMMdd')"
    
    if (-not (Test-Path $archiveDir)) {
        New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    }
    
    $archivedCount = 0
    foreach ($svc in $services) {
        $path = "$logDir/$svc"
        if (Test-Path $path) {
            Get-ChildItem -Path $path -File | Where-Object { 
                $_.LastWriteTime -lt $archiveDate 
            } | ForEach-Object {
                Move-Item -Path $_.FullName -Destination "$archiveDir/$($svc)_$($_.Name)"
                $archivedCount++
            }
        }
    }
    
    if ($archivedCount -gt 0) {
        # Compress archive
        Compress-Archive -Path "$archiveDir/*" -DestinationPath "$archiveDir.zip" -Force
        Remove-Item -Path $archiveDir -Recurse -Force
        Write-Host "✅ Archived $archivedCount log files to $archiveDir.zip" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  No old logs to archive" -ForegroundColor Blue
    }
}

function Clean-Logs {
    Write-Host "`nCLEANING OLD LOGS..." -ForegroundColor Red
    Write-Host "This will delete logs older than 30 days. Continue? (y/N): " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host
    
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        $cleanDate = (Get-Date).AddDays(-30)
        $cleanedCount = 0
        
        foreach ($svc in $services) {
            $path = "$logDir/$svc"
            if (Test-Path $path) {
                Get-ChildItem -Path $path -File | Where-Object { 
                    $_.LastWriteTime -lt $cleanDate 
                } | ForEach-Object {
                    Remove-Item -Path $_.FullName -Force
                    $cleanedCount++
                }
            }
        }
        
        # Clean old archives
        Get-ChildItem -Path $logDir -Filter "archive-*.zip" | Where-Object { 
            $_.LastWriteTime -lt $cleanDate 
        } | ForEach-Object {
            Remove-Item -Path $_.FullName -Force
            $cleanedCount++
        }
        
        Write-Host "✅ Cleaned $cleanedCount old log files" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  Log cleanup cancelled" -ForegroundColor Blue
    }
}

# Main script logic
if ($Start) {
    Start-LogCollection
} elseif ($Stop) {
    Stop-LogCollection  
} elseif ($Status) {
    Show-LogStatus
} elseif ($Tail) {
    Show-LiveLogs -ServiceName $Service
} elseif ($Archive) {
    Archive-Logs
} elseif ($Clean) {
    Clean-Logs
} else {
    Write-Host "`nUSAGE:" -ForegroundColor Yellow
    Write-Host "  .\log-manager.ps1 -Start          # Start log collection" -ForegroundColor White
    Write-Host "  .\log-manager.ps1 -Status         # Show log status" -ForegroundColor White
    Write-Host "  .\log-manager.ps1 -Tail [-Service service] # Show live logs" -ForegroundColor White
    Write-Host "  .\log-manager.ps1 -Archive        # Archive old logs" -ForegroundColor White
    Write-Host "  .\log-manager.ps1 -Clean          # Clean very old logs" -ForegroundColor White
    Write-Host "  .\log-manager.ps1 -Stop           # Stop log collection" -ForegroundColor White
    Write-Host ""
    Write-Host "Available services: n8n, caddy, postgres, grafana, all" -ForegroundColor Cyan
}

Write-Host "`nCURRENT DEPLOYMENT STATUS:" -ForegroundColor Cyan
docker-compose -f docker-compose-fixed.yml ps

Write-Host "`nLOGGING INFRASTRUCTURE:" -ForegroundColor Cyan
Write-Host "• Log Directory: $((Get-Item $logDir).FullName)" -ForegroundColor White
Write-Host "• Services Monitored: $($services -join ', ')" -ForegroundColor White
Write-Host "• Total Log Size: $([math]::Round((Get-ChildItem -Path $logDir -File -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2))MB" -ForegroundColor White
