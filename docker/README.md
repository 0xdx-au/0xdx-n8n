# 🔐 Secure N8N Deployment with Docker

**Timestamp:** 2025-07-20 CH41B01  
**Maintainer:** 0xdx  
**Security Level:** High  
**License:** MIT

## 🎯 Overview

This is an enterprise-grade, security-hardened N8N deployment using Docker with comprehensive monitoring, intrusion detection, and security best practices. The deployment includes:

- **N8N Workflow Automation Platform** with security hardening
- **Caddy Reverse Proxy** with automatic HTTPS and security headers  
- **PostgreSQL Database** with encryption and authentication hardening
- **Prometheus & Grafana** for monitoring and alerting
- **OWASP ZAP** for automated security scanning
- **Fail2Ban** for intrusion detection and prevention

## 🛡️ Security Features

### 🔒 Application Security
- Multi-stage Docker builds with minimal attack surface
- Non-root user execution across all containers
- Read-only filesystems with specific write mounts
- Security capabilities dropped and only essential ones added
- Container resource limits and security contexts

### 🌐 Network Security  
- Isolated Docker networks with no inter-container communication by default
- Custom subnet ranges for network segmentation
- Rate limiting and DDoS protection via Caddy
- Automatic HTTPS with strong TLS configuration
- Security headers (HSTS, CSP, X-Frame-Options, etc.)

### 🔐 Authentication & Authorization
- Multi-layer authentication (Basic Auth + N8N Auth)
- Secure password policies and encryption
- JWT token rotation and secure cookies
- Database authentication with SCRAM-SHA-256

### 📊 Monitoring & Logging
- Comprehensive health checks for all services
- Structured logging with rotation and retention
- Prometheus metrics collection and alerting
- Grafana dashboards for visualization
- Fail2Ban intrusion detection

### 🔍 Security Scanning
- Automated OWASP ZAP security scanning
- Container vulnerability scanning
- Configuration security validation

## 📋 Prerequisites

- **Docker Desktop** (latest version)
- **Docker Compose** v2.x+
- **PowerShell** 5.1+ (Windows)
- **8GB+ RAM** (recommended)
- **20GB+ Free Disk Space**

## 🚀 Quick Start

### 1. Test Deployment (Development)
```powershell
.\start-secure.ps1 -Test
```
Access at: http://localhost:5678

### 2. Secure Production Deployment
```powershell  
.\start-secure.ps1
```
Access at: https://localhost

### 3. Management Commands
```powershell
# Check status
.\start-secure.ps1 -Status

# View logs
.\start-secure.ps1 -Logs

# Stop deployment
.\start-secure.ps1 -Stop
```

## 🔧 Configuration

### Environment Variables (.env.secure)
```env
# N8N Configuration
N8N_ENCRYPTION_KEY=your-super-secure-key-here
N8N_BASIC_AUTH_USER=admin  
N8N_BASIC_AUTH_PASSWORD=your-secure-password

# Database Configuration
POSTGRES_DB=n8n_secure_db
POSTGRES_USER=n8n_secure_user
POSTGRES_PASSWORD=your-db-password

# Monitoring
GRAFANA_ADMIN_PASSWORD=your-grafana-password
```

⚠️ **IMPORTANT:** Change all default passwords before production use!

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐
│   Internet      │───▶│    Caddy     │───▶│     N8N     │
│                 │    │ (Port 443)   │    │ (Port 5678) │
└─────────────────┘    └──────────────┘    └─────────────┘
                              │                    │
                              ▼                    ▼
                       ┌──────────────┐    ┌─────────────┐
                       │   Grafana    │    │ PostgreSQL  │
                       │ (Port 3000)  │    │ (Port 5432) │
                       └──────────────┘    └─────────────┘
                              │
                              ▼
                       ┌──────────────┐
                       │ Prometheus   │
                       │ (Port 9090)  │
                       └──────────────┘
```

## 📊 Monitoring & Dashboards

### Access Points
- **N8N Interface:** https://localhost
- **Grafana Dashboards:** https://localhost/grafana  
- **Prometheus Metrics:** https://localhost/metrics
- **Health Check:** https://localhost/health

### Default Credentials
- **N8N:** admin / SecureN8NPassword123!
- **Grafana:** admin / SecureGrafanaAdmin789!

## 🔧 Customization

### Adding Custom N8N Nodes
1. Create custom Dockerfile extending `Dockerfile.secure`
2. Install additional packages in the builder stage
3. Rebuild with: `docker-compose build --no-cache`

### Security Configuration
- **Caddy:** Modify `security/Caddyfile`
- **PostgreSQL:** Edit `security/postgresql.conf`  
- **Fail2Ban:** Configure `security/fail2ban/jail.conf`
- **Prometheus:** Update `security/prometheus.yml`

## 🚨 Security Considerations

### Production Deployment Checklist
- [ ] Change all default passwords
- [ ] Generate unique encryption keys
- [ ] Configure SSL certificates (replace self-signed)  
- [ ] Set up external log aggregation
- [ ] Configure backup strategy for volumes
- [ ] Review and customize security policies
- [ ] Set up monitoring alerts
- [ ] Perform security testing

### Network Security
- The deployment uses custom Docker networks with restricted communication
- Fail2Ban monitors logs and automatically blocks suspicious IPs
- Rate limiting prevents abuse and DDoS attacks
- All HTTP traffic is redirected to HTTPS

### Data Security  
- Database connections use encrypted authentication
- N8N data is encrypted at rest using AES-256
- Sensitive files are mounted read-only where possible
- Container filesystems are read-only with specific writable mounts

## 🔍 Troubleshooting

### Common Issues

**1. Docker Permission Errors (Windows)**
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**2. Port Conflicts**
```powershell
# Check port usage
netstat -an | findstr ":443"
netstat -an | findstr ":80"  
```

**3. Container Health Failures**  
```powershell
# Check container logs
docker-compose -f docker-compose.secure.yml logs n8n-app-secure
```

**4. Volume Permission Issues**
```powershell
# Reset volume permissions
docker-compose -f docker-compose.secure.yml down -v
Remove-Item -Recurse -Force volumes
.\start-secure.ps1
```

### Debug Mode
For debugging issues, enable verbose logging:
```powershell
$env:COMPOSE_LOG_LEVEL="DEBUG"
.\start-secure.ps1 -Logs
```

## 📚 Additional Resources

### Documentation
- [N8N Documentation](https://docs.n8n.io)
- [Caddy Documentation](https://caddyserver.com/docs)  
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

### Security Guides
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Container Security Best Practices](https://sysdig.com/blog/docker-security-best-practices/)

## 🤝 Contributing

When contributing to this deployment:
1. Follow the existing security practices
2. Test changes in the test environment first
3. Update documentation for any configuration changes
4. Ensure all security scans pass

## 📄 License

MIT License - See LICENSE file for details.

## 🎯 Dedicated to CH41B01

*This secure N8N deployment is dedicated to CH41B01 - representing the pursuit of excellence in security engineering and automation.*

---

**Created with security-first principles by 0xdx**  
**For questions or support, refer to the troubleshooting section above.**
