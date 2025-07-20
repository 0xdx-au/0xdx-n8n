# 0xdx-n8n: Secure N8N Deployment Suite

A comprehensive, security-hardened deployment solution for N8N workflow automation across Windows, Linux, and macOS platforms using containerized environments with advanced monitoring and security testing capabilities.

**⚡ Built with ❤️ for enterprise workflow automation security**

**Updated:** $(date)

## Overview

This repository provides enterprise-grade security deployment scripts for N8N with integrated monitoring via Podman/Docker web interfaces, automated security testing with OWASP ZAP, and comprehensive vulnerability scanning capabilities.

## Features

### Core Security Features
- Multi-platform deployment (Windows, Linux, macOS)
- Hardened Docker containers with minimal attack surface
- Podman integration for rootless container execution
- Network segmentation and firewall configuration
- Encrypted data volumes and secure secrets management
- Automated security scanning with OWASP ZAP
- Vulnerability assessment integration
- Compliance monitoring and reporting

### Platform Support
- **Windows**: PowerShell-based deployment with Windows Defender integration
- **Linux**: Shell scripts supporting major distributions (Ubuntu, CentOS, Debian, Fedora)
- **macOS**: Homebrew-compatible installation with macOS security features

### Monitoring & Management
- Podman web GUI for container monitoring
- Health check endpoints and alerting
- Log aggregation and security event monitoring
- Performance metrics collection
- Automated backup and recovery procedures

## 🚀 Production Implementation

### Current Deployment
The platform is deployed with the following production-ready components:

- **🔒 Web Dashboard**: http://localhost/ (System overview & navigation)
- **🏠 N8N Workflow Designer**: http://localhost:8080/ (Direct access, fully functional)
- **📊 Grafana Analytics**: http://localhost/grafana/ (System monitoring)
- **📊 System Status API**: http://localhost/status (JSON health endpoint)

### Service Architecture
```
┌─────────────┐    ┌──────────────┐    ┌────────────┐
│   Nginx     │────│  Dashboard   │    │  Grafana   │
│   Proxy     │    │   (HTTP)     │    │ (Analytics)│
│   :80       │    │             │    │           │
└─────────────┘    └──────────────┘    └────────────┘
       │
┌─────────────┐    ┌──────────────┐    ┌────────────┐
│     N8N     │────│ PostgreSQL   │    │  ClamAV    │
│ Workflows   │    │  Database    │    │ Antivirus  │
│   :8080     │    │    :5432     │    │   :3310    │
└─────────────┘    └──────────────┘    └────────────┘
       │
┌─────────────┐    ┌──────────────┐    ┌────────────┐
│ Security    │────│ DNS Security │    │   Logs     │
│  Scanner    │    │ (Cloudflare) │    │ & Audits   │
│  (SAST)     │    │   DoH/DoT    │    │  Volume    │
└─────────────┘    └──────────────┘    └────────────┘
```

## Quick Start

### Prerequisites
- Docker & Docker Compose
- 4GB+ RAM
- 10GB+ disk space

### Windows Deployment
```powershell
.\scripts\deploy-windows.ps1 -Environment production -SecurityLevel high
```

### Linux Deployment
```bash
./scripts/deploy-linux.sh --env production --security-level high
```

### macOS Deployment
```bash
./scripts/deploy-macos.sh --env production --security-level high
```

## Security Architecture

### Container Security
- Non-root user execution
- Read-only filesystem where possible
- Capability dropping
- Seccomp and AppArmor profiles
- Resource limits and quotas

### Network Security
- Custom Docker networks with isolation
- TLS encryption for all communications
- Certificate management and rotation
- Firewall rules and port restrictions
- VPN integration support

### Data Security
- Encrypted volumes using LUKS/BitLocker
- Secure secret management with external providers
- Regular automated backups
- Data retention policies
- Audit logging for all operations

## Testing & Quality Assurance

### Automated Security Testing
- OWASP ZAP integration for web application security
- Container image vulnerability scanning
- Network penetration testing
- Configuration compliance checking
- Dependency vulnerability assessment

### Continuous Integration
- GitHub Actions workflows for testing
- Automated security scans on commits
- Multi-platform compatibility testing
- Performance benchmarking
- Security regression testing

## Configuration

### Environment Variables
```bash
# Security Configuration
N8N_SECURITY_LEVEL=high
N8N_ENCRYPTION_KEY=your-encryption-key
N8N_TLS_ENABLED=true
N8N_FIREWALL_ENABLED=true

# Monitoring Configuration
PODMAN_GUI_ENABLED=true
MONITORING_PORT=9090
ALERTS_ENABLED=true

# Testing Configuration
ZAP_ENABLED=true
VULN_SCANNING=true
```

### Security Profiles
- **Development**: Basic security for testing environments
- **Staging**: Enhanced security with monitoring
- **Production**: Maximum security with full compliance

## Directory Structure

```
0xdx-n8n/
├── scripts/
│   ├── deploy-windows.ps1     # Windows deployment script
│   ├── deploy-linux.sh        # Linux deployment script
│   ├── deploy-macos.sh        # macOS deployment script
│   ├── security/              # Security configuration scripts
│   ├── monitoring/            # Monitoring setup scripts
│   └── testing/               # Testing and validation scripts
├── docker/
│   ├── Dockerfile.secure      # Hardened N8N container
│   ├── docker-compose.yml     # Multi-service composition
│   └── security/              # Security policies and configs
├── configs/
│   ├── n8n/                   # N8N configuration files
│   ├── nginx/                 # Reverse proxy configs
│   ├── monitoring/            # Monitoring configurations
│   └── security/              # Security policy files
├── tests/
│   ├── security/              # Security test suites
│   ├── integration/           # Integration tests
│   └── performance/           # Performance tests
└── docs/
    ├── security-guide.md      # Comprehensive security guide
    ├── deployment-guide.md    # Deployment instructions
    └── troubleshooting.md     # Troubleshooting guide
```

## Security Best Practices

### Container Hardening
- Use minimal base images (Alpine or distroless)
- Regular security updates and patching
- Remove unnecessary packages and utilities
- Implement proper user permissions
- Use multi-stage builds to reduce attack surface

### Access Control
- Role-based access control (RBAC)
- Multi-factor authentication (MFA)
- API key rotation policies
- Session management and timeouts
- Audit trail for all administrative actions

### Network Security
- Network segmentation using Docker networks
- TLS/SSL for all communications
- Certificate pinning where applicable
- Rate limiting and DDoS protection
- Intrusion detection and prevention

## Monitoring and Alerting

### Health Monitoring
- Container health checks
- Application performance monitoring
- Resource utilization tracking
- Error rate monitoring
- Response time analysis

### Security Monitoring
- Security event logging
- Anomaly detection
- Compliance monitoring
- Vulnerability tracking
- Incident response automation

## Backup and Recovery

### Automated Backups
- Daily encrypted backups
- Multi-location backup storage
- Backup integrity verification
- Point-in-time recovery capability
- Disaster recovery procedures

### Recovery Testing
- Regular recovery drills
- Recovery time objective (RTO) testing
- Recovery point objective (RPO) validation
- Failover testing procedures
- Business continuity planning

## Compliance and Auditing

### Compliance Standards
- SOC 2 Type II readiness
- GDPR compliance features
- HIPAA security controls
- ISO 27001 alignment
- PCI DSS considerations

### Audit Features
- Comprehensive audit logging
- Compliance reporting
- Access audit trails
- Configuration change tracking
- Security incident documentation

## Troubleshooting

### Common Issues
- Container startup failures
- Network connectivity problems
- Permission and access issues
- Performance optimization
- Security configuration errors

### Support Resources
- Detailed error codes and solutions
- Log analysis procedures
- Performance tuning guides
- Security hardening checklists
- Community support channels

## Contributing

This project follows strict security guidelines and requires thorough testing of all contributions. Please review the security guidelines before submitting changes.

## License

MIT License - Full commercial rights reserved for the original author.

## Support

For enterprise support and custom deployment assistance, contact the development team.

---

**Dedicated to CH41B01**

*Last updated: 2025-07-20*
