# UTMStack Ubuntu Server Deployment Guide

This guide provides step-by-step instructions for deploying UTMStack on Ubuntu Server, based on the current working configuration that resolves common deployment issues.

## Prerequisites

### System Requirements
- **OS**: Ubuntu 22.04 LTS (recommended)
- **CPU**: Minimum 4 cores (8+ recommended for production)
- **RAM**: Minimum 16GB (32GB+ recommended for production)
- **Storage**: Minimum 150GB SSD (500GB+ recommended for production)
- **Network**: Static IP address recommended

### Software Requirements
- Docker Engine 20.10+
- Docker Compose 2.0+
- Node.js 18+ (for frontend builds)
- Git

## Step 1: System Preparation

### 1.1 Update System Packages
```bash
sudo apt update && sudo apt upgrade -y
```

### 1.2 Install Required Packages
```bash
sudo apt install -y curl wget git build-essential
```

### 1.3 Install Docker Engine
```bash
# Remove old Docker versions
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install Docker dependencies
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker
```

### 1.4 Install Docker Compose (if not using plugin)
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 1.5 Install Node.js (for frontend builds)
```bash
# Install Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

## Step 2: Clone UTMStack Repository

### 2.1 Clone the Repository
```bash
cd /opt
sudo git clone https://github.com/utmstack/UTMStack.git
sudo chown -R $USER:$USER /opt/UTMStack
cd /opt/UTMStack
```

### 2.2 Verify Repository Structure
```bash
ls -la
# Should see: agent-manager, backend, frontend, docker-compose.yaml, etc.
```

## Step 3: Configure Environment

### 3.1 Update Docker Compose Configuration
The `docker-compose.yaml` file is already configured correctly, but verify these key settings:

```yaml
# Key environment variables in docker-compose.yaml:
# - DB_PASS: utmstack (database password)
# - INTERNAL_KEY: utmstack-internal-key-2024
# - ENCRYPTION_KEY: utmstack-encryption-key-2024
```

### 3.2 Configure Frontend Environment
```bash
# Edit the production environment file
nano frontend/src/environments/environment.prod.ts
```

Ensure the following configuration:
```typescript
export const environment = {
  production: true,
  SERVER_API_URL: 'http://localhost:8080/',  // Backend API URL
  WEBSOCKET_URL: 'ws://localhost:8080/',     // WebSocket URL
  SESSION_AUTH_TOKEN: window.location.host.split(':')[0].toLocaleUpperCase(),
  SERVER_API_CONTEXT: '',
  BUILD_TIMESTAMP: new Date().getTime(),
  DEBUG_INFO_ENABLED: true,
  VERSION: '0.0.1'
};
```

### 3.3 Configure Angular Build Settings
```bash
# Edit angular.json to ensure proper build configuration
nano frontend/angular.json
```

Key settings to verify:
```json
{
  "production": {
    "optimization": false,        // Disable optimization to prevent ES6 issues
    "buildOptimizer": false,      // Disable build optimizer
    "es5BrowserSupport": true     // Enable ES5 browser support
  },
  "scripts": [
    "node_modules/jquery/dist/jquery.min.js"  // Only include jQuery, remove other libraries
  ]
}
```

### 3.4 Configure TypeScript Settings
```bash
# Edit TypeScript configuration
nano frontend/tsconfig.json
```

Ensure these settings:
```json
{
  "compilerOptions": {
    "target": "es2015",           // ES2015 target
    "module": "es2015",           // ES2015 modules
    "moduleResolution": "node"
  }
}
```

## Step 4: Build Frontend

### 4.1 Install Frontend Dependencies
```bash
cd frontend
npm install
```

### 4.2 Build Frontend with Legacy Provider
```bash
# Use legacy OpenSSL provider for Node.js compatibility
export NODE_OPTIONS="--openssl-legacy-provider"
npm run build
```

### 4.3 Verify Build Output
```bash
ls -la dist/utm-stack/
# Should contain: index.html, main.*.js, polyfills.*.js, styles.*.css, etc.
```

## Step 5: Configure Nginx for Frontend

### 5.1 Update Nginx Configuration
```bash
nano frontend/nginx/default.conf
```

Ensure cache-busting headers are present:
```nginx
# Cache-busting for JavaScript files
location ~* \.(js|css)$ {
    try_files $uri =404;
    add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    add_header Pragma "no-cache" always;
    add_header Expires "0" always;
    add_header ETag "";
}

# Handle all other requests (Angular routing)
location / {
    try_files $uri $uri/ /index.html;
}
```

## Step 6: Deploy with Docker Compose

### 6.1 Build and Start Services
```bash
cd /opt/UTMStack

# Build and start all services
docker-compose up -d --build

# Check service status
docker-compose ps
```

### 6.2 Monitor Service Logs
```bash
# Check all services
docker-compose logs -f

# Check specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f db
```

### 6.3 Verify Services are Running
```bash
# Check if services are accessible
curl -s http://localhost:3000 | head -10          # Frontend
curl -s http://localhost:8080/api/ping            # Backend API
curl -s http://localhost:9200                     # OpenSearch
```

## Step 7: Configure Firewall

### 7.1 Install UFW (if not installed)
```bash
sudo apt install -y ufw
```

### 7.2 Configure Firewall Rules
```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow UTMStack Web Interface
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp

# Allow UTMStack Backend API
sudo ufw allow 8080/tcp

# Allow OpenSearch (if needed externally)
sudo ufw allow 9200/tcp

# Enable firewall
sudo ufw enable
```

## Step 8: Access UTMStack

### 8.1 Default Login Credentials
- **URL**: `http://your-server-ip:3000`
- **Username**: `admin`
- **Password**: `utmstack`

### 8.2 Verify Login
1. Open browser and navigate to `http://your-server-ip:3000`
2. You should see the UTMStack login page
3. Enter credentials: `admin` / `utmstack`
4. You should be logged in successfully

## Step 9: Post-Deployment Configuration

### 9.1 Change Default Password
1. Log in to UTMStack
2. Go to User Management
3. Change the default admin password
4. Update the `DB_PASS` in docker-compose.yaml if needed

### 9.2 Configure SSL/HTTPS (Recommended for Production)
```bash
# Install Certbot for Let's Encrypt
sudo apt install -y certbot python3-certbot-nginx

# Generate SSL certificate
sudo certbot --nginx -d your-domain.com
```

### 9.3 Set Up Log Rotation
```bash
# Create log rotation configuration
sudo nano /etc/logrotate.d/utmstack

# Add the following content:
/opt/UTMStack/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
```

## Step 10: Monitoring and Maintenance

### 10.1 Set Up System Monitoring
```bash
# Install htop for system monitoring
sudo apt install -y htop

# Monitor system resources
htop
```

### 10.2 Backup Configuration
```bash
# Create backup script
sudo nano /opt/backup-utmstack.sh

# Add backup commands
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backups/utmstack_$DATE"

mkdir -p $BACKUP_DIR
cp -r /opt/UTMStack $BACKUP_DIR/
docker-compose -f /opt/UTMStack/docker-compose.yaml exec db pg_dump -U utm utmstack > $BACKUP_DIR/database_backup.sql

echo "Backup completed: $BACKUP_DIR"
```

### 10.3 Update UTMStack
```bash
# Stop services
cd /opt/UTMStack
docker-compose down

# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose up -d --build
```

## Troubleshooting Common Issues

### Issue 1: Frontend Shows White Page
**Symptoms**: Browser shows white page with console errors
**Solution**: 
1. Check if frontend build completed successfully
2. Verify NODE_OPTIONS="--openssl-legacy-provider" was used
3. Check browser console for JavaScript errors
4. Clear browser cache

### Issue 2: "Unexpected token 'export'" Error
**Symptoms**: JavaScript syntax errors in console
**Solution**:
1. Ensure `optimization: false` in angular.json
2. Remove problematic third-party libraries from scripts array
3. Verify TypeScript module settings

### Issue 3: API Connection Issues
**Symptoms**: Login form doesn't appear or API calls fail
**Solution**:
1. Verify SERVER_API_URL in environment.prod.ts
2. Check if backend service is running: `docker-compose logs backend`
3. Test API endpoint: `curl http://localhost:8080/api/ping`

### Issue 4: Database Connection Issues
**Symptoms**: Backend fails to start or database errors
**Solution**:
1. Check database service: `docker-compose logs db`
2. Verify database credentials in docker-compose.yaml
3. Ensure database volume is properly mounted

### Issue 5: Port Conflicts
**Symptoms**: Services fail to start due to port conflicts
**Solution**:
1. Check which ports are in use: `sudo netstat -tulpn | grep :3000`
2. Stop conflicting services or change ports in docker-compose.yaml
3. Restart Docker services: `sudo systemctl restart docker`

## Security Considerations

### 1. Change Default Credentials
- Change default admin password immediately
- Update database passwords
- Rotate API keys and encryption keys

### 2. Network Security
- Use firewall to restrict access
- Consider VPN for remote access
- Enable HTTPS/SSL in production

### 3. Regular Updates
- Keep system packages updated
- Monitor UTMStack releases
- Apply security patches promptly

### 4. Backup Strategy
- Regular database backups
- Configuration file backups
- Test restore procedures

## Performance Optimization

### 1. Resource Allocation
- Monitor CPU and memory usage
- Adjust Docker resource limits if needed
- Consider horizontal scaling for large deployments

### 2. Storage Optimization
- Use SSD storage for better performance
- Implement log rotation
- Monitor disk space usage

### 3. Network Optimization
- Use dedicated network for UTMStack services
- Consider load balancing for high availability
- Monitor network bandwidth usage

## Support and Documentation

- **Official Documentation**: https://docs.utmstack.com
- **GitHub Repository**: https://github.com/utmstack/UTMStack
- **Community Support**: Discord server (link in README)
- **Issue Reporting**: GitHub Issues

## Conclusion

This deployment guide provides a comprehensive approach to deploying UTMStack on Ubuntu Server. By following these steps and addressing the common issues we encountered, you should have a stable and functional UTMStack deployment.

Remember to:
1. Always test in a development environment first
2. Keep backups of your configuration
3. Monitor system resources and logs
4. Stay updated with UTMStack releases
5. Follow security best practices

For additional support, refer to the official UTMStack documentation or community resources.
