#!/bin/bash
# 2025-07-20 CH41B01

set -e
ENVIRONMENT="${1:-production}"
SECURITY_LEVEL="${2:-high}"
DATAPATH="/usr/local/var/n8n/data"
LOGPATH="/usr/local/var/log/n8n"
PORT=5678
ENABLE_MONITORING=true
ENABLE_ZAP=true

function check_prerequisites {
  echo "Checking prerequisites..."
  
  if ! command -v docker &> /dev/null; then
    echo "Installing Docker using Homebrew..."
    if ! command -v brew &> /dev/null; then
      echo "Homebrew is not installed. Installing Homebrew first..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install --cask docker
    echo "Please start Docker Desktop manually and run the script again."
    exit 1
  fi
  
  if ! docker info &> /dev/null; then
    echo "Docker daemon is not running. Please start Docker Desktop."
    exit 1
  fi
  
  echo "Prerequisites check passed."
}

function initialize_directories {
  echo "Initializing directories..."
  sudo mkdir -p "$DATAPATH"/workflows "$DATAPATH"/credentials "$LOGPATH"
  sudo chown $(whoami):staff "$DATAPATH" "$LOGPATH" -R
  sudo chmod 700 "$DATAPATH" "$LOGPATH" -R
  echo "Directories initialized with secure permissions."
}

function configure_firewall {
  echo "Configuring macOS firewall..."
  
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
  
  echo "macOS firewall configured for enhanced security."
}

function generate_secure_config {
  echo "Generating secure configuration..."
  local env_file="../configs/n8n/.env.$ENVIRONMENT"
  cat << EOF > "$env_file"
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
N8N_USER_FOLDER=$DATAPATH
N8N_LOG_LEVEL=$( [ "$ENVIRONMENT" = "production" ] && echo "warn" || echo "info" )
N8N_LOG_OUTPUT="file"
N8N_LOG_FILE_LOCATION="$LOGPATH/n8n.log"
N8N_SECURE_COOKIE="true"
N8N_JWT_AUTH_HEADER="true"
N8N_JWT_AUTH_HEADER_VALUE_PREFIX="Bearer"
N8N_BASIC_AUTH_ACTIVE="true"
N8N_DISABLE_UI=$( [ "$SECURITY_LEVEL" = "high" ] && echo "true" || echo "false" )
WEBHOOK_URL="https://localhost:$PORT"
N8N_PROTOCOL="https"
N8N_SSL_CERT="/certs/server.crt"
N8N_SSL_KEY="/certs/server.key"
NODE_ENV=$ENVIRONMENT
EOF
  echo "Configuration saved to $env_file"
}

function generate_tls_certificates {
  echo "Generating TLS certificates..."
  local cert_path="../docker/security/certs"
  mkdir -p "$cert_path"
  
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$cert_path/server.key" -out "$cert_path/server.crt" \
    -subj "/C=AU/ST=State/L=City/O=Organization/CN=localhost" \
    -extensions v3_req -config <(
      echo '[req]'
      echo 'distinguished_name = req_distinguished_name'
      echo 'x509_extensions = v3_req'
      echo 'prompt = no'
      echo '[req_distinguished_name]'
      echo 'C = AU'
      echo 'ST = State'
      echo 'L = City'
      echo 'O = Organization'
      echo 'CN = localhost'
      echo '[v3_req]'
      echo 'keyUsage = keyEncipherment, dataEncipherment'
      echo 'extendedKeyUsage = serverAuth'
      echo 'subjectAltName = @alt_names'
      echo '[alt_names]'
      echo 'DNS.1 = localhost'
      echo 'IP.1 = 127.0.0.1'
    )
  
  echo "TLS certificates generated."
}

function deploy_security_scanning {
  if [ "$ENABLE_ZAP" = true ]; then
    echo "Setting up OWASP ZAP..."
    docker-compose -f ../docker/docker-compose.zap.yml up -d
    echo "OWASP ZAP security scanning configured."
  fi
}

function deploy_monitoring {
  if [ "$ENABLE_MONITORING" = true ]; then
    echo "Setting up monitoring..."
    docker-compose -f ../docker/docker-compose.monitoring.yml up -d
    echo "Monitoring stack configured."
  fi
}

function deploy_n8n_container {
  echo "Deploying N8N container..."
  cd ../docker
  docker-compose build --no-cache
  docker-compose up -d
  cd - > /dev/null
  echo "N8N container deployed."
}

function setup_launch_daemon {
  echo "Setting up macOS launch daemon for auto-start..."
  
  local plist_file="$HOME/Library/LaunchAgents/com.0xdx.n8n.plist"
  cat << EOF > "$plist_file"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.0xdx.n8n</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/docker-compose</string>
        <string>-f</string>
        <string>$(pwd)/../docker/docker-compose.yml</string>
        <string>up</string>
        <string>-d</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOGPATH/launchd.log</string>
    <key>StandardErrorPath</key>
    <string>$LOGPATH/launchd.error.log</string>
</dict>
</plist>
EOF
  
  launchctl load "$plist_file"
  echo "Launch daemon configured for auto-start."
}

function main {
  check_prerequisites
  initialize_directories
  configure_firewall
  generate_secure_config
  generate_tls_certificates
  deploy_security_scanning
  deploy_monitoring
  deploy_n8n_container
  setup_launch_daemon
  
  echo ""
  echo "=== Deployment completed successfully! ==="
  echo "N8N URL: https://localhost:$PORT"
  echo "Data Path: $DATAPATH"
  echo "Log Path: $LOGPATH"
  [ "$ENABLE_MONITORING" = true ] && echo "Monitoring: http://localhost:9090"
  [ "$ENABLE_ZAP" = true ] && echo "Security Scanning: http://localhost:8090"
}

main "$@"
