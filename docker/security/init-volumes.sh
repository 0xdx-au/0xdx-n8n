#!/bin/bash

# Volume permissions initialization script
# Ensures proper ownership and permissions for security logs volume

set -e

echo "Initializing volume permissions..."

# Create necessary directories and set ownership
mkdir -p /var/log/security
mkdir -p /var/log/clamav
mkdir -p /var/log/grafana
mkdir -p /var/log/nginx
mkdir -p /var/log/postgresql

# Set ownership for scanner user (UID 1001)
chown -R 1001:1001 /var/log/security

# Set ownership for other services
chown -R 100:101 /var/log/clamav      # ClamAV user
chown -R 472:472 /var/log/grafana      # Grafana user
chown -R 101:101 /var/log/nginx        # Nginx user
chown -R 999:999 /var/log/postgresql   # PostgreSQL user

# Set proper permissions
chmod -R 755 /var/log/security
chmod -R 755 /var/log/clamav
chmod -R 755 /var/log/grafana
chmod -R 755 /var/log/nginx
chmod -R 755 /var/log/postgresql

echo "Volume permissions initialized successfully"
