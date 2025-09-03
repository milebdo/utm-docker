# UTMStack Demo Deployment Guide
## For Limited Resources: 4 cores, 8GB RAM, 50GB storage

### 🎯 **Purpose**
This guide is for deploying UTMStack as a **demo/testing environment only**. It's optimized to work within your server's resource constraints.

### 📋 **Prerequisites**
- Ubuntu 22.04 LTS server
- Root access via SSH
- Internet connection for package downloads
- Target server: 38.244.180.220

### 🚀 **Quick Start**

#### 1. **SSH to Your Server**
```bash
ssh root@38.244.180.220
# Enter your password when prompted
```

#### 2. **Download and Run Build Script**
```bash
# Download the build script
wget https://raw.githubusercontent.com/your-repo/utmstack-demo/main/build_utmstack_demo.sh

# Make it executable
chmod +x build_utmstack_demo.sh

# Run the build script
./build_utmstack_demo.sh
```

#### 3. **Start UTMStack Demo**
```bash
# Start the service
systemctl start utmstack-demo

# Check status
systemctl status utmstack-demo

# View logs
journalctl -u utmstack-demo -f
```

### 🔧 **Resource Allocation**

The demo build is configured to use minimal resources:

| Service | RAM Limit | RAM Reserved | Purpose |
|---------|-----------|--------------|---------|
| PostgreSQL | 1GB | 512MB | Database |
| Elasticsearch | 2GB | 1GB | Log storage |
| Logstash | 1GB | 512MB | Log processing |
| Backend | 1GB | 512MB | API server |
| Frontend | 256MB | 128MB | Web UI |
| **Total** | **5.25GB** | **2.65GB** | **~2.75GB for system** |

### 📊 **Monitoring Resources**

#### **Memory Usage**
```bash
# Check memory usage
free -h

# Monitor memory in real-time
watch -n 1 'free -h'
```

#### **Disk Usage**
```bash
# Check disk space
df -h

# Monitor disk usage
watch -n 5 'df -h'
```

#### **Docker Resources**
```bash
# Check running containers
docker ps

# Check container resource usage
docker stats

# View service logs
docker-compose -f /opt/utmstack-demo/docker-compose.demo.yml logs -f
```

### 🌐 **Access UTMStack**

Once running, access UTMStack at:
- **URL**: `http://38.244.180.220`
- **Username**: `admin`
- **Password**: `utmstackdemo2024`

### ⚠️ **Important Limitations**

#### **Performance Expectations**
- **Slower startup**: Services may take 5-10 minutes to fully start
- **Limited throughput**: Not suitable for high-volume log processing
- **Memory pressure**: System may become slow under heavy load

#### **Storage Considerations**
- **50GB total**: ~30GB available after OS and dependencies
- **Log retention**: Limited log storage (adjust as needed)
- **Backup space**: Minimal space for backups

#### **Not Suitable For**
- Production environments
- High-volume log processing
- Long-term data retention
- Multiple concurrent users

### 🛠️ **Troubleshooting**

#### **Service Won't Start**
```bash
# Check service status
systemctl status utmstack-demo

# Check Docker status
systemctl status docker

# View detailed logs
journalctl -u utmstack-demo -n 100
```

#### **Out of Memory**
```bash
# Check memory usage
free -h

# Restart with lower limits
cd /opt/utmstack-demo
docker-compose -f docker-compose.demo.yml down
docker-compose -f docker-compose.demo.yml up -d
```

#### **Out of Disk Space**
```bash
# Check disk usage
df -h

# Clean Docker images
docker system prune -a

# Clean old logs
docker system prune -f
```

### 🔄 **Maintenance**

#### **Daily Operations**
```bash
# Check service status
systemctl status utmstack-demo

# Monitor resources
docker stats

# View recent logs
docker-compose -f /opt/utmstack-demo/docker-compose.demo.yml logs --tail=50
```

#### **Weekly Maintenance**
```bash
# Update system packages
apt update && apt upgrade -y

# Clean Docker system
docker system prune -f

# Check disk space
df -h
```

#### **Monthly Maintenance**
```bash
# Restart services for stability
systemctl restart utmstack-demo

# Check for updates
cd /opt/utmstack-demo
git pull origin v10
```

### 🚪 **Stopping/Removing**

#### **Stop Demo**
```bash
# Stop the service
systemctl stop utmstack-demo

# Or stop manually
cd /opt/utmstack-demo
docker-compose -f docker-compose.demo.yml down
```

#### **Remove Demo**
```bash
# Stop and remove containers
cd /opt/utmstack-demo
docker-compose -f docker-compose.demo.yml down -v

# Remove data volumes
docker volume prune -f

# Remove service
systemctl disable utmstack-demo
systemctl stop utmstack-demo
rm /etc/systemd/system/utmstack-demo.service

# Remove directory
rm -rf /opt/utmstack-demo
```

### 📞 **Support**

For issues with this demo build:
1. Check the troubleshooting section above
2. Review service logs
3. Monitor system resources
4. Consider upgrading server resources for better performance

### 🔮 **Future Upgrades**

When you're ready for production:
1. **Upgrade RAM**: Minimum 16GB, recommended 32GB+
2. **Upgrade Storage**: Minimum 150GB, recommended 500GB+
3. **Use official installer**: Download from [utmstack.com/install](https://utmstack.com/install)
4. **Follow production guide**: Use the official documentation

---

**Remember**: This is a **DEMO ONLY** build. It's perfect for testing, learning, and development, but not for production use.
