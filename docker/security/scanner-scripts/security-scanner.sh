#!/bin/bash

# 0xdx-n8n Security Scanner
# Automated SAST/DAST with ClamAV integration
# Runs on rebuild or every 24 hours

set -euo pipefail

# Configuration
SCAN_INTERVAL=${SCAN_INTERVAL:-86400}  # 24 hours
REBUILD_SCAN=${REBUILD_SCAN:-true}
LOG_LEVEL=${LOG_LEVEL:-INFO}
LOG_FILE="/var/log/security/security-scanner.log"
RESULTS_FILE="/var/log/security/scan-results.json"

# Logging function
log() {
    local level=$1
    shift
    local message="$(date -Iseconds) [$level] $*"
    echo "$message"
    echo "$message" >> "$LOG_FILE" 2>/dev/null || true
}

# Initialize logging
mkdir -p "$(dirname "$LOG_FILE")"
log "INFO" "0xdx-n8n Security Scanner Starting..."

# Function to run ClamAV scan - REAL ANTIVIRUS SCANNING
run_clamav_scan() {
    log "INFO" "Running REAL ClamAV antivirus scan..."
    
    # Wait for ClamAV daemon to be ready
    local attempts=0
    while [ $attempts -lt 30 ]; do
        if echo "PING" | nc -w 5 n8n-clamav 3310 | grep -q "PONG"; then
            break
        fi
        sleep 2
        ((attempts++))
    done
    
    local scan_result="UNKNOWN"
    local threats_found=0
    local files_scanned=0
    
    # Perform REAL scan of mounted N8N data volume
    if [ -d "/scan/n8n" ]; then
        log "INFO" "Scanning N8N data directory for malware..."
        
        # Count files to scan
        files_scanned=$(find /scan/n8n -type f | wc -l)
        
        # Run actual ClamAV scan
        if clamdscan --multiscan --infected --no-summary /scan/n8n > /tmp/clamav_scan.log 2>&1; then
            scan_result="CLEAN"
            log "INFO" "ClamAV scan completed: $files_scanned files scanned, no threats detected"
        else
            # Check if threats were found or if it's a connection error
            threats_found=$(grep -c "FOUND" /tmp/clamav_scan.log || echo "0")
            if [ "$threats_found" -gt 0 ]; then
                scan_result="INFECTED"
                log "CRITICAL" "ClamAV detected $threats_found threats! Check /tmp/clamav_scan.log"
            else
                scan_result="ERROR"
                log "ERROR" "ClamAV scan failed - daemon not accessible"
            fi
        fi
    else
        scan_result="ERROR"
        log "ERROR" "N8N data directory not accessible for scanning"
    fi
    
    echo "{\"clamav\": {\"status\": \"$scan_result\", \"files_scanned\": $files_scanned, \"threats_found\": $threats_found, \"timestamp\": \"$(date -Iseconds)\"}}" > /tmp/clamav_result.json
}

# Function to run SAST (Static Application Security Testing)
run_sast_scan() {
    log "INFO" "Running SAST scan..."
    
    local sast_results=""
    
    # Bandit for Python security issues
    if find /scan -name "*.py" | head -1 > /dev/null 2>&1; then
        log "INFO" "Running Bandit Python security scan..."
        bandit -r /scan -f json -o /tmp/bandit_results.json 2>/dev/null || true
        sast_results="$sast_results,\"bandit\": $(cat /tmp/bandit_results.json 2>/dev/null || echo '{}')"
    fi
    
    # Semgrep for general SAST
    log "INFO" "Running Semgrep SAST scan..."
    semgrep --config=auto /scan --json --output=/tmp/semgrep_results.json 2>/dev/null || true
    sast_results="$sast_results,\"semgrep\": $(cat /tmp/semgrep_results.json 2>/dev/null || echo '{}')"
    
    # Safety for Python dependencies
    if find /scan -name "requirements*.txt" -o -name "Pipfile*" | head -1 > /dev/null 2>&1; then
        log "INFO" "Running Safety dependency check..."
        safety check --json --output=/tmp/safety_results.json 2>/dev/null || true
        sast_results="$sast_results,\"safety\": $(cat /tmp/safety_results.json 2>/dev/null || echo '{}')"
    fi
    
    # npm audit for Node.js dependencies
    if find /scan -name "package.json" | head -1 > /dev/null 2>&1; then
        log "INFO" "Running npm audit..."
        cd /scan && npm audit --json > /tmp/npm_audit.json 2>/dev/null || true
        sast_results="$sast_results,\"npm_audit\": $(cat /tmp/npm_audit.json 2>/dev/null || echo '{}')"
    fi
    
    echo "{\"sast\": {$sast_results, \"timestamp\": \"$(date -Iseconds)\"}}" > /tmp/sast_result.json
    log "INFO" "SAST scan completed"
}

# Function to run DAST (Dynamic Application Security Testing)
run_dast_scan() {
    log "INFO" "Running DAST scan..."
    
    # Wait for services to be ready
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://n8n-app:5678/healthz >/dev/null 2>&1; then
            break
        fi
        sleep 5
        ((attempt++))
    done
    
    if [ $attempt -eq $max_attempts ]; then
        log "WARN" "N8N service not accessible for DAST scan"
        echo "{\"dast\": {\"status\": \"SKIPPED\", \"reason\": \"Service not accessible\", \"timestamp\": \"$(date -Iseconds)\"}}" > /tmp/dast_result.json
        return
    fi
    
    # Basic port scan
    log "INFO" "Running network security scan..."
    nmap -sS -O n8n-app 2>/dev/null > /tmp/nmap_results.txt || true
    
    # Nikto web vulnerability scan
    log "INFO" "Running web vulnerability scan..."
    nikto -h http://n8n-app:5678 -Format json -output /tmp/nikto_results.json 2>/dev/null || true
    
    local dast_summary="{\"nmap\": \"$(wc -l < /tmp/nmap_results.txt) lines\", \"nikto\": \"$(wc -l < /tmp/nikto_results.json 2>/dev/null || echo 0) findings\"}"
    echo "{\"dast\": {\"summary\": $dast_summary, \"timestamp\": \"$(date -Iseconds)\"}}" > /tmp/dast_result.json
    log "INFO" "DAST scan completed"
}

# Function to run container security scan
run_container_scan() {
    log "INFO" "Running container security scan..."
    
    local container_issues=0
    
    # Check for privileged containers
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -v "NAMES" | while read -r line; do
        container_name=$(echo "$line" | awk '{print $1}')
        if docker inspect "$container_name" | jq -r '.[0].HostConfig.Privileged' | grep -q true; then
            log "WARN" "Privileged container detected: $container_name"
            ((container_issues++))
        fi
    done 2>/dev/null; then
        log "INFO" "Container privilege check completed"
    fi
    
    # Check for containers running as root
    docker ps --format "{{.Names}}" | while read -r container_name; do
        if [ -n "$container_name" ]; then
            user_id=$(docker exec "$container_name" id -u 2>/dev/null || echo "unknown")
            if [ "$user_id" = "0" ]; then
                log "WARN" "Container running as root: $container_name"
                ((container_issues++))
            fi
        fi
    done 2>/dev/null || true
    
    echo "{\"container_security\": {\"issues_found\": $container_issues, \"timestamp\": \"$(date -Iseconds)\"}}" > /tmp/container_result.json
    log "INFO" "Container security scan completed"
}

# Function to generate comprehensive security report
generate_report() {
    log "INFO" "Generating security report..."
    
    local timestamp=$(date -Iseconds)
    local report_file="/var/log/security/security-report-$(date +%Y%m%d-%H%M%S).json"
    
    # Combine all scan results
    {
        echo "{"
        echo "  \"scan_metadata\": {"
        echo "    \"timestamp\": \"$timestamp\","
        echo "    \"scanner_version\": \"0xdx-n8n-scanner-1.0\","
        echo "    \"scan_type\": \"full\""
        echo "  },"
        cat /tmp/clamav_result.json 2>/dev/null | sed 's/^/  /' | sed 's/$/,/' || echo "  \"clamav\": {\"status\": \"ERROR\"},"
        cat /tmp/sast_result.json 2>/dev/null | sed 's/^/  /' | sed 's/$/,/' || echo "  \"sast\": {\"status\": \"ERROR\"},"
        cat /tmp/dast_result.json 2>/dev/null | sed 's/^/  /' | sed 's/$/,/' || echo "  \"dast\": {\"status\": \"ERROR\"},"
        cat /tmp/container_result.json 2>/dev/null | sed 's/^/  /' || echo "  \"container_security\": {\"status\": \"ERROR\"}"
        echo "}"
    } > "$report_file"
    
    # Create symlink to latest report
    ln -sf "$report_file" "$RESULTS_FILE"
    
    log "INFO" "Security report generated: $report_file"
}

# Function to check if rebuild scan is needed
check_rebuild_scan() {
    if [ "$REBUILD_SCAN" = "true" ]; then
        local last_rebuild=$(docker system events --since 1h --filter event=create --format '{{.Time}}' | tail -1)
        if [ -n "$last_rebuild" ]; then
            log "INFO" "Recent container rebuild detected, triggering security scan"
            return 0
        fi
    fi
    return 1
}

# Main execution loop
main() {
    log "INFO" "Security scanner initialized with $SCAN_INTERVAL second interval"
    
    while true; do
        log "INFO" "Starting security scan cycle..."
        
        # Run all security scans
        run_clamav_scan &
        CLAMAV_PID=$!
        
        run_sast_scan &
        SAST_PID=$!
        
        run_dast_scan &
        DAST_PID=$!
        
        run_container_scan &
        CONTAINER_PID=$!
        
        # Wait for all scans to complete
        wait $CLAMAV_PID $SAST_PID $DAST_PID $CONTAINER_PID
        
        # Generate comprehensive report
        generate_report
        
        log "INFO" "Security scan cycle completed. Next scan in $SCAN_INTERVAL seconds."
        
        # Check for rebuild trigger or wait for interval
        if ! check_rebuild_scan; then
            sleep "$SCAN_INTERVAL"
        fi
    done
}

# Signal handlers
trap 'log "INFO" "Security scanner shutting down..."; exit 0' TERM INT

# Start main execution
main
