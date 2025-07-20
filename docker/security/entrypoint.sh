#!/bin/sh
# 2025-07-20 CH41B01

set -e

echo "Starting secure N8N container..."

if [ "$N8N_SECURITY_LEVEL" = "high" ]; then
    echo "Applying high security configuration..."
    export N8N_DISABLE_UI=true
    export N8N_BASIC_AUTH_ACTIVE=true
    export N8N_SECURE_COOKIE=true
fi

if [ ! -f "/home/n8n/.n8n/config" ]; then
    echo "Initializing N8N configuration..."
    mkdir -p /home/n8n/.n8n
    touch /home/n8n/.n8n/config
fi

if [ "$1" = "n8n" ]; then
    echo "Starting N8N with security hardening..."
    exec su-exec n8n "$@"
else
    exec "$@"
fi
