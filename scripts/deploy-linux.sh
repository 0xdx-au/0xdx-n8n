#!/bin/bash
# 2025-07-20 CH41B01

set -e
ENVIRONMENT="${1:-production}"
SECURITY_LEVEL="${2:-high}"
DATAPATH="/var/lib/n8n/data"
LOGPATH="/var/log/n8n"
PORT=5678
ENABLE_MONITORING=true
ENABLE_ZAP=true

function check_prerequisites {
  echo "Checking prerequisites..."
  if ! command -v docker &> /dev/null; then
    echo "Docker is not installed." >&2
    exit 1
  fi
  if ! docker info &> /dev/null; then
    echo "Docker daemon is not running." >&2
    exit 1
  fi
  echo "Prerequisites check passed."
}

function initialize_directories {
  echo "Initializing directories..."
  sudo mkdir -p "$DATAPATH"/workflows "$DATAPATH"/credentials "$LOGPATH"
  sudo chown 1000:1000 "$DATAPATH" "$LOGPATH" -R
  sudo chmod 700 "$DATAPATH" "$LOGPATH" -R
  echo "Directories initialized with secure permissions."
}

function configure_firewall {
  echo "Configuring firewall..."
  sudo ufw allow $PORT/tcp
  echo "Firewall configured to allow port $PORT."
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
    -subj "/C=AU/ST=State/L=City/O=Organization/CN=localhost"
  echo "TLS certificates generated."
}

function deploy_security_scanning {
  if [ "$ENABLE_ZAP" = true ]; then
    echo "Setting up OWASP ZAP..."
    docker-compose -f docker-compose.zap.yml up -d
    echo "OWASP ZAP security scanning configured."
  fi
}

function deploy_monitoring {
  if [ "$ENABLE_MONITORING" = true ]; then
    echo "Setting up monitoring..."
    docker-compose -f docker-compose.monitoring.yml up -d
    echo "Monitoring stack configured."
  fi
}

function deploy_n8n_container {
  echo "Deploying N8N container..."
  docker-compose build --no-cache
  docker-compose up -d
  echo "N8N container deployed."
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
  echo "Deployment completed successfully!"
}

main "$@"

