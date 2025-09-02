# UTMStack Ubuntu Server Installation

Quick start guide for installing UTMStack on Ubuntu Server.

## Quick Installation

### 1. Clone Repository
```bash
git clone https://github.com/utmstack/UTMStack.git
cd UTMStack
```

### 2. Install Dependencies
```bash
./install-ubuntu.sh
```

### 3. Build UTMStack
```bash
./build.sh
```

### 4. Deploy
```bash
./deploy-ubuntu.sh
```

## What Gets Installed

- **Build Tools**: Go 1.23+, Node.js 16.x, Maven, Java
- **System Dependencies**: Docker, Nginx, PostgreSQL client, Redis tools
- **Security**: UFW firewall, fail2ban, SSL support
- **Monitoring**: htop, iotop, nethogs, glances
- **UTMStack Services**: Agent and Agent Manager as systemd services

## Access Points

- **Web UI**: http://your-server-ip:8080
- **Nginx Proxy**: http://your-server-ip
- **API**: http://your-server-ip:9000

## Service Management

```bash
# Check status
sudo systemctl status utmstack-*

# View logs
sudo journalctl -u utmstack-agent -f

# Restart services
sudo systemctl restart utmstack-*
```

## Documentation

- **Full Guide**: [UBUNTU-INSTALLATION.md](UBUNTU-INSTALLATION.md)
- **Build Script**: [build.sh](build.sh)
- **Install Script**: [install-ubuntu.sh](install-ubuntu.sh)
- **Deploy Script**: [deploy-ubuntu.sh](deploy-ubuntu.sh)

## Support

- **Issues**: https://github.com/utmstack/UTMStack/issues
- **Docs**: https://docs.utmstack.com

---

**Note**: Requires Ubuntu Server 18.04+ with sudo privileges.
