# UTMStack Single Script Installation Guide

## Quick Installation

Deploy UTMStack on Ubuntu Server with a single command:

```bash
# Download and run the installation script
curl -fsSL https://raw.githubusercontent.com/utmstack/UTMStack/main/install-utmstack.sh | sudo bash
```

Or if you have the repository locally:

```bash
# Make script executable and run
chmod +x install-utmstack.sh
sudo ./install-utmstack.sh
```

## What the Script Does

The `install-utmstack.sh` script automatically:

### 1. **System Preparation**
- Updates Ubuntu packages
- Installs required dependencies (curl, wget, git, build-essential)
- Checks system requirements (CPU, RAM, disk space)

### 2. **Software Installation**
- Installs Docker Engine 20.10+
- Installs Docker Compose 2.0+
- Installs Node.js 18 LTS

### 3. **UTMStack Setup**
- Clones the UTMStack repository to `/opt/UTMStack`
- Configures frontend environment files
- Updates Angular build configuration
- Fixes TypeScript settings
- Builds the frontend with proper Node.js compatibility

### 4. **Service Deployment**
- Configures Nginx with cache-busting headers
- Deploys all services using Docker Compose
- Configures firewall rules
- Verifies all services are running

### 5. **Verification**
- Tests frontend accessibility (port 3000)
- Tests backend API (port 8080)
- Tests database connectivity
- Tests OpenSearch (port 9200)

## Prerequisites

- **OS**: Ubuntu 22.04 LTS (recommended)
- **CPU**: 4+ cores
- **RAM**: 16GB+
- **Storage**: 150GB+ free space
- **Network**: Internet connection for downloads
- **Permissions**: Root or sudo access

## Installation Process

1. **Download and Run**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/utmstack/UTMStack/main/install-utmstack.sh | sudo bash
   ```

2. **Follow Prompts**:
   - The script will check system requirements
   - Ask for confirmation before proceeding
   - Show progress for each installation step

3. **Wait for Completion**:
   - Installation typically takes 10-15 minutes
   - All services will be automatically configured

4. **Access UTMStack**:
   - URL: `http://your-server-ip:3000`
   - Username: `admin`
   - Password: `utmstack`

## Post-Installation

### Default Access
- **Frontend**: http://your-server-ip:3000
- **Backend API**: http://your-server-ip:8080
- **OpenSearch**: http://your-server-ip:9200

### Default Credentials
- **Username**: `admin`
- **Password**: `utmstack`

### Useful Commands
```bash
# Check service status
docker-compose -f /opt/UTMStack/docker-compose.yaml ps

# View logs
docker-compose -f /opt/UTMStack/docker-compose.yaml logs -f

# Restart services
docker-compose -f /opt/UTMStack/docker-compose.yaml restart

# Stop services
docker-compose -f /opt/UTMStack/docker-compose.yaml down

# Run troubleshooting
/opt/UTMStack/troubleshoot.sh
```

## Troubleshooting

If installation fails or services don't start:

1. **Check Logs**:
   ```bash
   docker-compose -f /opt/UTMStack/docker-compose.yaml logs
   ```

2. **Run Troubleshooting Script**:
   ```bash
   /opt/UTMStack/troubleshoot.sh
   ```

3. **Common Issues**:
   - **Port conflicts**: Check if ports 3000, 8080, 9200 are in use
   - **Insufficient resources**: Ensure minimum system requirements
   - **Network issues**: Check internet connectivity and firewall

## Security Recommendations

After installation:

1. **Change Default Password**:
   - Log in to UTMStack
   - Go to User Management
   - Change admin password

2. **Configure SSL/HTTPS**:
   ```bash
   # Install Certbot
   sudo apt install certbot python3-certbot-nginx
   
   # Generate SSL certificate
   sudo certbot --nginx -d your-domain.com
   ```

3. **Update Firewall**:
   - The script opens necessary ports
   - Consider restricting access to specific IPs

4. **Set Up Backups**:
   ```bash
   # Create backup script
   sudo nano /opt/backup-utmstack.sh
   ```

## Uninstallation

To remove UTMStack:

```bash
# Stop and remove containers
cd /opt/UTMStack
docker-compose down

# Remove volumes (WARNING: This deletes all data)
docker-compose down -v

# Remove directory
sudo rm -rf /opt/UTMStack

# Remove Docker (optional)
sudo apt remove docker-ce docker-ce-cli containerd.io
```

## Support

- **Documentation**: See `UBUNTU_DEPLOYMENT_GUIDE.md` for detailed instructions
- **Troubleshooting**: Run `/opt/UTMStack/troubleshoot.sh`
- **Issues**: Check GitHub Issues or community support

## Script Features

The installation script includes:

- ✅ **Error Handling**: Exits on any error with clear messages
- ✅ **Progress Indicators**: Shows colored status for each step
- ✅ **System Checks**: Validates requirements before installation
- ✅ **Automatic Configuration**: Fixes all known deployment issues
- ✅ **Service Verification**: Tests all services after deployment
- ✅ **Security Setup**: Configures firewall and basic security
- ✅ **Troubleshooting**: Provides diagnostic information

## Customization

To customize the installation:

1. **Edit Configuration**:
   ```bash
   nano install-utmstack.sh
   ```

2. **Modify Variables**:
   - `UTMSTACK_DIR`: Installation directory
   - `NODE_VERSION`: Node.js version
   - `REPO_URL`: Repository URL

3. **Run Custom Script**:
   ```bash
   sudo ./install-utmstack.sh
   ```

This single script approach makes UTMStack deployment much simpler and more reliable!
