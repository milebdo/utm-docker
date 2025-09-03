#!/bin/bash

# UTMStack Demo Quick Start Script
# Run this directly on your Ubuntu 22.04 server
# Target: 38.244.180.220

set -e

echo "🚀 UTMStack Demo Quick Start"
echo "============================="
echo "This script will set up UTMStack demo on your server"
echo "Target: 38.244.180.220"
echo "Resources: 4 cores, 8GB RAM, 50GB storage"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root"
   echo "   Use: sudo su -"
   exit 1
fi

# Check Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
if [[ "$UBUNTU_VERSION" != "22.04" ]]; then
    echo "⚠️  Warning: This script is designed for Ubuntu 22.04"
    echo "   Current version: $UBUNTU_VERSION"
    echo "   Continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo "✅ System check passed"
echo ""

# Update system
echo "📦 Updating system packages..."
apt update -y
apt upgrade -y

# Install essential packages
echo "🔧 Installing essential packages..."
apt install -y \
    wget \
    curl \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    lsb-release \
    net-tools

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker
systemctl start docker
systemctl enable docker

# Install Java 11
echo "☕ Installing Java 11..."
apt install -y openjdk-11-jdk openjdk-11-jre

# Install Node.js 16
echo "🟢 Installing Node.js 16..."
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt install -y nodejs

# Install Go
echo "🔵 Installing Go..."
GO_VERSION="1.21.0"
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
source /etc/profile

# Install Maven
echo "📚 Installing Maven..."
apt install -y maven

echo ""
echo "✅ All dependencies installed successfully!"
echo ""

# Create UTMStack directory
UTMSTACK_DIR="/opt/utmstack-demo"
echo "📁 Creating UTMStack directory: $UTMSTACK_DIR"
mkdir -p $UTMSTACK_DIR
cd $UTMSTACK_DIR

# Clone repository
echo "📥 Cloning UTMStack repository..."
git clone https://github.com/utmstack/UTMStack.git .
git checkout v10

# Create minimal configuration
echo "⚙️  Creating demo configuration..."
cat > /root/utmstack-demo.yml << EOF
main_server: $(hostname -I | awk '{print $1}')
branch: v10
password: utmstackdemo2024
data_dir: /opt/utmstack-demo/data
server_type: aio
server_name: $(hostname)
internal_key: $(openssl rand -hex 32)
EOF

# Build components
echo "🔨 Building UTMStack components..."

# Build backend
echo "  - Building backend (Java)..."
cd backend
mvn clean package -DskipTests -Dmaven.javadoc.skip=true
cd ..

# Build frontend
echo "  - Building frontend (Angular)..."
cd frontend
npm install
npm run build --prod
cd ..

# Build Go services
echo "  - Building Go services..."
cd agent
go mod download
go build -o utmstack-agent .
cd ..

cd agent-manager
go mod download
go build -o utmstack-agent-manager .
cd ..

# Create minimal Docker Compose
echo "🐳 Creating Docker Compose configuration..."
cat > docker-compose.demo.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: utmstack
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: utmstackdemo2024
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx1g"
      - xpack.security.enabled=false
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G

  logstash:
    image: ghcr.io/utmstack/utmstack/logstash:v10
    environment:
      - CONFIG_RELOAD_AUTOMATIC=true
      - LS_JAVA_OPTS=-Xms256m -Xmx512m
      - PIPELINE_WORKERS=2
    volumes:
      - ./filters:/etc/logstash/conf.d
    ports:
      - "5044:5044"
    depends_on:
      - elasticsearch
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/utmstack
      - SPRING_DATASOURCE_USERNAME=postgres
      - SPRING_DATASOURCE_PASSWORD=utmstackdemo2024
    depends_on:
      - postgres
      - elasticsearch
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  frontend:
    image: nginx:alpine
    volumes:
      - ./frontend/dist:/usr/share/nginx/html
      - ./nginx.conf:/etc/nginx/nginx.conf
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - backend
    deploy:
      resources:
        limits:
          memory: 256M
        reservations:
          memory: 128M

volumes:
  postgres_data:
  elasticsearch_data:
EOF

# Create nginx config
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    upstream backend {
        server backend:8080;
    }

    server {
        listen 80;
        server_name _;

        location / {
            root /usr/share/nginx/html;
            try_files $uri $uri/ /index.html;
        }

        location /api {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
EOF

# Create startup script
cat > start-demo.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting UTMStack Demo..."
echo "Resources allocated:"
echo "- PostgreSQL: 1GB RAM"
echo "- Elasticsearch: 2GB RAM"
echo "- Logstash: 1GB RAM"
echo "- Backend: 1GB RAM"
echo "- Frontend: 256MB RAM"
echo "- Total: ~5.5GB RAM (leaving 2.5GB for system)"
echo ""

cd /opt/utmstack-demo
docker-compose -f docker-compose.demo.yml up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 30

echo ""
echo "✅ UTMStack Demo is starting up!"
echo "🌐 Access the application at: http://$(hostname -I | awk '{print $1}')"
echo "🔑 Default credentials: admin / utmstackdemo2024"
echo ""
echo "📋 Useful commands:"
echo "- Stop: docker-compose -f docker-compose.demo.yml down"
echo "- View logs: docker-compose -f docker-compose.demo.yml logs -f"
echo "- Check status: docker-compose -f docker-compose.demo.yml ps"
EOF

chmod +x start-demo.sh

# Create systemd service
echo "🔧 Creating systemd service..."
cat > /etc/systemd/system/utmstack-demo.service << EOF
[Unit]
Description=UTMStack Demo Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/utmstack-demo
ExecStart=/opt/utmstack-demo/start-demo.sh
ExecStop=/usr/bin/docker-compose -f /opt/utmstack-demo/docker-compose.demo.yml down

[Install]
WantedBy=multi-user.target
EOF

# Enable service
systemctl daemon-reload
systemctl enable utmstack-demo.service

echo ""
echo "🎉 UTMStack Demo build completed successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Start the demo: systemctl start utmstack-demo"
echo "2. Check status: systemctl status utmstack-demo"
echo "3. View logs: journalctl -u utmstack-demo -f"
echo "4. Access web UI: http://$(hostname -I | awk '{print $1}')"
echo ""
echo "⚠️  Important Notes:"
echo "- This is a DEMO build with limited resources"
echo "- Not suitable for production use"
echo "- Services may take 5-10 minutes to fully start"
echo "- Monitor system resources during operation"
echo ""
echo "🔧 Manual control:"
echo "- Start: cd /opt/utmstack-demo && ./start-demo.sh"
echo "- Stop: cd /opt/utmstack-demo && docker-compose -f docker-compose.demo.yml down"
echo "- Restart: cd /opt/utmstack-demo && docker-compose -f docker-compose.demo.yml restart"
echo ""
echo "📊 Resource monitoring:"
echo "- Memory: free -h"
echo "- Disk: df -h"
echo "- Docker: docker stats"
echo ""
echo "✅ Ready to start UTMStack demo!"
echo ""
echo "🚀 Starting demo now..."
systemctl start utmstack-demo

echo ""
echo "⏳ Demo is starting... This may take 5-10 minutes."
echo "Check status with: systemctl status utmstack-demo"
echo "View logs with: journalctl -u utmstack-demo -f"
echo ""
echo "🌐 Once ready, access at: http://$(hostname -I | awk '{print $1}')"
echo "🔑 Login with: admin / utmstackdemo2024"
