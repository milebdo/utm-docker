# UTMStack Ubuntu Server Installation Guide

This guide provides comprehensive instructions for installing UTMStack on Ubuntu Server (18.04 LTS, 20.04 LTS, 22.04 LTS, and 24.04 LTS).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Installation](#quick-installation)
3. [Manual Installation](#manual-installation)
4. [Post-Installation Configuration](#post-installation-configuration)
5. [Troubleshooting](#troubleshooting)
6. [Production Deployment](#production-deployment)

## Prerequisites

### System Requirements
- **OS**: Ubuntu Server 18.04 LTS, 20.04 LTS, 22.04 LTS, or 24.04 LTS
- **CPU**: 2+ cores (4+ recommended for production)
- **RAM**: 4GB minimum (8GB+ recommended for production)
- **Storage**: 20GB minimum (100GB+ recommended for production)
- **Network**: Internet access for package downloads

### User Requirements
- Non-root user with sudo privileges
- SSH access to the server

## Quick Installation

### Option 1: Automated Installation Script

1. **Clone the UTMStack repository:**
   ```bash
   git clone https://github.com/utmstack/UTMStack.git
   cd UTMStack
   ```

2. **Run the automated installation script:**
   ```bash
   ./install-ubuntu.sh
   ```

3. **Build UTMStack:**
   ```bash
   ./build.sh
   ```

4. **Deploy the binaries:**
   ```bash
   sudo cp bin/* /usr/local/bin/
   sudo chmod +x /usr/local/bin/utmstack-*
   ```

5. **Start the services:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable utmstack-agent
   sudo systemctl enable utmstack-agent-manager
   sudo systemctl start utmstack-agent
   sudo systemctl start utmstack-agent-manager
   ```

### Option 2: Build Script with Auto-Detection

The `build.sh` script automatically detects Ubuntu Server and installs dependencies:

```bash
./build.sh
```

## Manual Installation

If you prefer to install dependencies manually or need to customize the installation:

### 1. Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Essential Build Tools

```bash
sudo apt install -y \
    build-essential \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    pkg-config \
    libssl-dev \
    libffi-dev \
    python3-dev \
    python3-pip \
    python3-venv \
    default-jdk \
    maven \
    nodejs \
    npm
```

### 3. Install Go 1.23+

```bash
# Download and install Go
GO_VERSION="1.23.0"
GO_ARCH="linux-amd64"
GO_TAR="go${GO_VERSION}.${GO_ARCH}.tar.gz"

wget "https://go.dev/dl/${GO_TAR}" -O /tmp/${GO_TAR}
sudo tar -C /usr/local -xzf /tmp/${GO_TAR}
rm /tmp/${GO_TAR}

# Add to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin

# Verify installation
go version
```

### 4. Install Node.js 16.x (for Angular 7 compatibility)

```bash
# Remove existing Node.js
sudo apt remove -y nodejs npm
sudo apt autoremove -y

# Install Node.js 16.x from NodeSource
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

### 5. Install Docker (Optional but Recommended)

```bash
# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker
```

### 6. Install Additional System Dependencies

```bash
sudo apt install -y \
    postgresql-client \
    redis-tools \
    nginx \
    certbot \
    python3-certbot-nginx \
    fail2ban \
    ufw \
    htop \
    iotop \
    nethogs \
    net-tools \
    vim \
    nano \
    tree \
    glances
```

### 7. Configure Firewall

```bash
# Enable UFW
sudo ufw --force enable

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow ssh

# Allow UTMStack ports
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8080/tcp  # UTMStack Web UI
sudo ufw allow 9000/tcp  # UTMStack API
sudo ufw allow 9200/tcp  # Elasticsearch
sudo ufw allow 9300/tcp  # Elasticsearch cluster
sudo ufw allow 5601/tcp  # Kibana
sudo ufw allow 5432/tcp  # PostgreSQL
sudo ufw allow 6379/tcp  # Redis

# Check status
sudo ufw status
```

### 8. Create UTMStack User and Directories

```bash
# Create UTMStack user
sudo useradd -m -s /bin/bash utmstack
sudo usermod -aG sudo utmstack

# Create directories
sudo mkdir -p /opt/utmstack
sudo mkdir -p /var/log/utmstack
sudo mkdir -p /etc/utmstack

# Set ownership
sudo chown -R utmstack:utmstack /opt/utmstack
sudo chown -R utmstack:utmstack /var/log/utmstack
sudo chown -R utmstack:utmstack /etc/utmstack
```

### 9. Install Python Dependencies

```bash
# Upgrade pip
pip install --user --upgrade pip

# Install virtualenv
pip install --user virtualenv
```

## Post-Installation Configuration

### 1. Create Systemd Service Files

#### UTMStack Agent Service

```bash
sudo tee /etc/systemd/system/utmstack-agent.service > /dev/null <<EOF
[Unit]
Description=UTMStack Agent
After=network.target
Wants=network.target

[Service]
Type=simple
User=utmstack
Group=utmstack
WorkingDirectory=/opt/utmstack
ExecStart=/usr/local/bin/utmstack-agent
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=utmstack-agent

[Install]
WantedBy=multi-user.target
EOF
```

#### UTMStack Agent Manager Service

```bash
sudo tee /etc/systemd/system/utmstack-agent-manager.service > /dev/null <<EOF
[Unit]
Description=UTMStack Agent Manager
After=network.target
Wants=network.target

[Service]
Type=simple
User=utmstack
Group=utmstack
WorkingDirectory=/opt/utmstack
ExecStart=/usr/local/bin/utmstack-agent-manager
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=utmstack-agent-manager

[Install]
WantedBy=multi-user.target
EOF
```

### 2. Configure Nginx (Reverse Proxy)

```bash
# Create Nginx configuration
sudo tee /etc/nginx/sites-available/utmstack > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/utmstack /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl restart nginx
```

### 3. Configure Log Rotation

```bash
sudo tee /etc/logrotate.d/utmstack > /dev/null <<EOF
/var/log/utmstack/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 utmstack utmstack
    postrotate
        systemctl reload utmstack-agent > /dev/null 2>&1 || true
        systemctl reload utmstack-agent-manager > /dev/null 2>&1 || true
    endscript
}
EOF
```

## Building and Deploying UTMStack

### 1. Build UTMStack

```bash
# Clone repository (if not already done)
git clone https://github.com/utmstack/UTMStack.git
cd UTMStack

# Build all components
./build.sh
```

### 2. Deploy Binaries

```bash
# Copy binaries to system directories
sudo cp bin/* /usr/local/bin/

# Set executable permissions
sudo chmod +x /usr/local/bin/utmstack-*

# Verify installation
ls -la /usr/local/bin/utmstack-*
```

### 3. Start Services

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable services
sudo systemctl enable utmstack-agent
sudo systemctl enable utmstack-agent-manager

# Start services
sudo systemctl start utmstack-agent
sudo systemctl start utmstack-agent-manager

# Check status
sudo systemctl status utmstack-*
```

### 4. Verify Installation

```bash
# Check service status
sudo systemctl status utmstack-agent
sudo systemctl status utmstack-agent-manager

# Check logs
sudo journalctl -u utmstack-agent -f
sudo journalctl -u utmstack-agent-manager -f

# Check if processes are running
ps aux | grep utmstack

# Check listening ports
sudo netstat -tlnp | grep utmstack
```

## Accessing UTMStack

### Web Interface
- **Direct access**: http://your-server-ip:8080
- **Through Nginx**: http://your-server-ip

### API Endpoints
- **Agent Manager API**: http://your-server-ip:9000
- **Agent API**: http://your-server-ip:8080

## Troubleshooting

### Common Issues

#### 1. Service Won't Start
```bash
# Check service status
sudo systemctl status utmstack-agent

# Check logs
sudo journalctl -u utmstack-agent -n 50

# Check if binary exists and is executable
ls -la /usr/local/bin/utmstack-agent
```

#### 2. Permission Issues
```bash
# Fix ownership
sudo chown -R utmstack:utmstack /opt/utmstack
sudo chown -R utmstack:utmstack /var/log/utmstack
sudo chown -R utmstack:utmstack /etc/utmstack

# Fix permissions
sudo chmod +x /usr/local/bin/utmstack-*
```

#### 3. Port Already in Use
```bash
# Check what's using the port
sudo netstat -tlnp | grep :8080

# Kill the process if needed
sudo kill -9 <PID>
```

#### 4. Dependency Issues
```bash
# Check Go version
go version

# Check Node.js version
node --version

# Check Java version
java -version

# Check Maven version
mvn --version
```

### Log Locations
- **System logs**: `/var/log/syslog`
- **UTMStack logs**: `/var/log/utmstack/`
- **Nginx logs**: `/var/log/nginx/`
- **Systemd logs**: `sudo journalctl -u utmstack-*`

## Production Deployment

### 1. SSL/TLS Configuration

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 2. Monitoring and Alerting

```bash
# Install monitoring tools
sudo apt install -y prometheus node-exporter grafana

# Configure monitoring for UTMStack services
```

### 3. Backup Strategy

```bash
# Create backup script
sudo tee /opt/utmstack/backup.sh > /dev/null <<EOF
#!/bin/bash
BACKUP_DIR="/backup/utmstack"
DATE=\$(date +%Y%m%d_%H%M%S)

mkdir -p \$BACKUP_DIR
tar -czf \$BACKUP_DIR/utmstack_\$DATE.tar.gz /opt/utmstack /var/log/utmstack /etc/utmstack

# Keep only last 7 days of backups
find \$BACKUP_DIR -name "utmstack_*.tar.gz" -mtime +7 -delete
EOF

sudo chmod +x /opt/utmstack/backup.sh

# Add to crontab
sudo crontab -e
# Add: 0 2 * * * /opt/utmstack/backup.sh
```

### 4. Performance Tuning

```bash
# Increase file descriptors
echo "utmstack soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "utmstack hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Optimize kernel parameters
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 5. Security Hardening

```bash
# Configure fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Regular security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## Maintenance

### Regular Tasks

1. **System Updates**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Service Restarts**
   ```bash
   sudo systemctl restart utmstack-agent
   sudo systemctl restart utmstack-agent-manager
   ```

3. **Log Rotation**
   ```bash
   sudo logrotate -f /etc/logrotate.d/utmstack
   ```

4. **Backup Verification**
   ```bash
   ls -la /backup/utmstack/
   ```

### Performance Monitoring

```bash
# Check resource usage
htop
iotop
nethogs

# Check disk usage
df -h
du -sh /var/log/utmstack/

# Check memory usage
free -h
```

## Support

- **Documentation**: https://docs.utmstack.com
- **GitHub Issues**: https://github.com/utmstack/UTMStack/issues
- **Community**: Join UTMStack community channels

## Version Compatibility

| UTMStack Version | Ubuntu Version | Go Version | Node.js Version | Java Version |
|------------------|----------------|------------|-----------------|--------------|
| Latest           | 18.04+        | 1.23+      | 16.x           | 8+           |

---

**Note**: This guide is designed for Ubuntu Server. For other distributions, please refer to the appropriate installation documentation.
