# 0xdx-n8n: Hardened Workflow Automation Platform

A production-ready n8n deployment with comprehensive security hardening, TLS 1.3 enforcement, and enterprise-grade monitoring capabilities.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          External Access Layer                      │
├─────────────────────────────────────────────────────────────────────┤
│                    HTTPS Only (TLS 1.3 Mandatory)                  │
│                         Port 443/80 -> 301                         │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────────┐
│                     Nginx Reverse Proxy                            │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Security Headers: HSTS, CSP, X-Frame-Options, X-XSS        │   │
│  │ TLS Termination: TLS 1.3 Only, Strong Ciphers             │   │
│  │ Certificate Management: Self-signed with auto-renewal      │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────┬─────────┬─────────┬─────────────────────────────────────┘
              │         │         │
        ┌─────▼───┐ ┌───▼───┐ ┌───▼──────┐
        │   /     │ │ /n8n/ │ │ /grafana/│
        │Dashboard│ │ App   │ │ Monitor  │
        └─────────┘ └───┬───┘ └────────┬─┘
                        │              │
┌───────────────────────▼──────────────▼─────────────────────────────┐
│                  Internal Network Bridge                          │
│                    172.20.0.0/16 (Isolated)                      │
├────────────┬──────────────┬──────────────┬──────────────┬─────────┤
│            │              │              │              │         │
│ ┌──────────▼───┐ ┌────────▼───┐ ┌────────▼──┐ ┌────────▼──┐ ┌───▼──┐│
│ │   N8N Core   │ │ PostgreSQL │ │  Grafana  │ │  ClamAV   │ │ DNS  ││
│ │ Workflow     │ │ Database   │ │ Analytics │ │ Antivirus │ │ Sec  ││
│ │ Engine       │ │            │ │           │ │           │ │      ││
│ │              │ │            │ │           │ │           │ │      ││
│ └──────────────┘ └────────────┘ └───────────┘ └───────────┘ └──────┘│
└─────────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼─────────────────────────────┐
│               Security Scanner Container                  │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ SAST: Static Application Security Testing          │ │
│  │ DAST: Dynamic Application Security Testing         │ │
│  │ Container Vulnerability Assessment                 │ │
│  │ ClamAV Integration & Malware Detection            │ │
│  │ Network Security Auditing                         │ │
│  └─────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────┘

Storage Volumes:
├── n8n_data:/home/node/.n8n (Persistent Workflows)
├── postgres_data:/var/lib/postgresql/data (Database)
├── grafana_data:/var/lib/grafana (Dashboards)
├── clamav_data:/var/lib/clamav (Virus Definitions)
├── nginx_logs:/var/log/nginx (Access/Error Logs)
└── security_logs:/opt/security/logs (Audit Trail)
```

## Security Implementation

### Transport Layer Security
- **TLS Version**: 1.3 exclusively (TLS 1.2 and below rejected)
- **HTTP Behavior**: All HTTP requests return 301 redirect to HTTPS
- **Certificate Management**: Self-signed certificates with automated generation
- **Cipher Suites**: OpenSSL default TLS 1.3 ciphers (secure by default)
- **HSTS**: Strict-Transport-Security with 1-year max-age and preload directive

### HTTP Security Headers
```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'
```

### Container Security
- **Privilege Escalation**: `no-new-privileges: true` on all containers
- **Capability Dropping**: Non-essential Linux capabilities removed
- **Root Prevention**: All services run as non-root users where possible
- **Read-only Filesystems**: Applied to containers where state persistence not required
- **Resource Limits**: Memory and CPU constraints defined per service

### Network Isolation
- **Bridge Network**: Isolated Docker bridge network (172.20.0.0/16)
- **Port Exposure**: Only reverse proxy ports (80/443) exposed to host
- **Inter-service Communication**: Internal DNS resolution within Docker network
- **External Dependencies**: Minimal external connections, DNS over HTTPS for security

### Authentication & Authorization
- **N8N Authentication**: Basic authentication with generated credentials
- **Grafana Access**: Administrative interface with secure session management
- **Database Access**: PostgreSQL with dedicated user accounts and connection pooling
- **API Security**: All endpoints require authentication, no anonymous access

### Monitoring & Logging
- **Access Logs**: Comprehensive Nginx access logging with IP tracking
- **Error Monitoring**: Centralized error logging across all services
- **Health Checks**: Docker health checks for service availability monitoring
- **Security Auditing**: Automated security scanning with ClamAV integration
- **Performance Metrics**: Grafana dashboards for system resource monitoring

### Data Protection
- **Database Encryption**: PostgreSQL with encrypted connections
- **Volume Security**: Persistent volumes with restricted access permissions
- **Backup Strategy**: Database dumps with encrypted storage
- **Secret Management**: Environment variables for sensitive configuration

## Technical Specifications

### Container Runtime
- **Base Images**: Official Alpine Linux images for minimal attack surface
- **Container Engine**: Docker with BuildKit for enhanced security
- **Orchestration**: Docker Compose with production-grade configuration
- **Health Monitoring**: Integrated health checks with automatic restart policies

### Database Configuration
- **Engine**: PostgreSQL 15 with Alpine Linux base
- **Connection Pooling**: Configured for optimal performance
- **Authentication**: SCRAM-SHA-256 password authentication
- **Network**: Internal network access only, no external exposure

### Reverse Proxy Configuration
- **Server**: Nginx with Alpine Linux base
- **SSL Termination**: TLS 1.3 with modern cipher suites
- **Load Balancing**: Upstream configuration for service routing
- **Static Assets**: Optimized serving of dashboard and monitoring interfaces

## Deployment

### Prerequisites
- Docker Engine 20.10+
- Docker Compose 2.0+
- Minimum 2GB RAM allocation
- 10GB available disk space

### Installation
```bash
git clone <repository-url>
cd 0xdx-n8n/docker
docker-compose -f docker-compose-production.yml up -d
```

### Service Endpoints
- **Main Dashboard**: https://localhost/
- **N8N Workflow Designer**: https://localhost/n8n/
- **Grafana Analytics**: https://localhost/grafana/
- **Health Check**: https://localhost/health
- **System Status**: https://localhost/status.json

### Configuration
Environment variables are defined in `docker-compose-production.yml`. Key configurations include:

- Database credentials and connection parameters
- N8N authentication settings
- Grafana administrative access
- Security scanner configuration
- SSL certificate paths

## Software Bill of Materials (SBOM)

### Core Components
- **n8n**: v1.0+ - Workflow Automation Platform (Apache-2.0)
- **PostgreSQL**: v15-alpine - Database Engine (PostgreSQL License)
- **Nginx**: v1.25-alpine - Reverse Proxy Server (BSD-2-Clause)
- **Grafana**: v10+ - Analytics Platform (AGPL-3.0)
- **ClamAV**: v1.0+ - Antivirus Engine (GPL-2.0)
- **Cloudflared**: latest - DNS over HTTPS (Apache-2.0)

### Base Images
- **Alpine Linux**: v3.18+ - Container Base OS (MIT)
- **Node.js**: v18-alpine - JavaScript Runtime (MIT)
- **Ubuntu**: 22.04 - Security Scanner Base (Various)

### Security Tools
- **OpenSSL**: v3.0+ - Cryptographic Library (Apache-2.0)
- **Fail2ban**: v0.11+ - Intrusion Prevention (GPL-2.0)
- **Nmap**: v7.80+ - Network Security Scanner (GPL-2.0)
- **Nikto**: v2.1+ - Web Vulnerability Scanner (GPL-2.0)
- **SSLyze**: v5.0+ - SSL Configuration Analyzer (AGPL-3.0)

### JavaScript Dependencies
- **express**: Web framework for Node.js (MIT)
- **helmet**: Security headers middleware (MIT)
- **jsonwebtoken**: JWT implementation (MIT)
- **bcrypt**: Password hashing library (MIT)
- **pg**: PostgreSQL client (MIT)

### System Libraries
- **glibc**: GNU C Library (LGPL-2.1)
- **libssl**: SSL/TLS implementation (Apache-2.0)
- **zlib**: Compression library (zlib)
- **curl**: Data transfer library (MIT-style)

## License

MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Security Considerations

This platform implements security controls appropriate for production environments. However, additional considerations for enterprise deployment include:

- Regular security updates and vulnerability patching
- External certificate authority for production TLS certificates
- Integration with enterprise identity providers (LDAP/SAML)
- Network segmentation and firewall rules
- Backup and disaster recovery procedures
- Security incident response procedures
- Compliance with organizational security policies

For security issues or questions, please review the security documentation and follow responsible disclosure practices.
