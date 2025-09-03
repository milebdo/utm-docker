#!/bin/bash

# UTMStack Demo Build Script for Limited Resources
# Optimized for: 4 cores, 8GB RAM, 50GB storage
# Usage: ./build_utmstack_demo.sh

set -e

echo "🚀 UTMStack Demo Build - Resource Optimized"
echo "============================================="
echo "Target Server: 38.244.180.220"
echo "Resources: 4 cores, 8GB RAM, 50GB storage"
echo "Purpose: Demo/Testing only"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   exit 1
fi

# System resource check
print_status "Checking system resources..."

# Check available memory
AVAILABLE_MEM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$AVAILABLE_MEM" -lt 6 ]; then
    print_warning "Available memory is low: ${AVAILABLE_MEM}GB (recommended: 6GB+)"
else
    print_success "Memory check passed: ${AVAILABLE_MEM}GB available"
fi

# Check available disk space
AVAILABLE_DISK=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_DISK" -lt 30 ]; then
    print_warning "Available disk space is low: ${AVAILABLE_DISK}GB (recommended: 30GB+)"
else
    print_success "Disk check passed: ${AVAILABLE_DISK}GB available"
fi

# Check CPU cores
CPU_CORES=$(nproc)
print_success "CPU cores detected: ${CPU_CORES}"

echo ""
print_status "Starting UTMStack demo build process..."
echo ""

# Update system packages
print_status "Updating system packages..."
apt update -y
apt upgrade -y

# Install essential dependencies
print_status "Installing essential dependencies..."
apt install -y \
    wget \
    curl \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    lsb-release

# Install Docker (required for UTMStack)
print_status "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Install Java 11 (required for backend)
print_status "Installing Java 11..."
apt install -y openjdk-11-jdk openjdk-11-jre

# Install Node.js 16 (for frontend build)
print_status "Installing Node.js 16..."
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt install -y nodejs

# Install Go (for agent and microservices)
print_status "Installing Go..."
GO_VERSION="1.21.0"
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
source /etc/profile

# Install Maven (for backend build)
print_status "Installing Maven..."
apt install -y maven

# Verify installations
print_status "Verifying installations..."
echo "Docker version:"
docker --version
echo "Java version:"
java -version
echo "Node.js version:"
node --version
echo "Go version:"
go version
echo "Maven version:"
mvn --version

echo ""
print_success "All dependencies installed successfully!"
echo ""

# Create UTMStack directory
UTMSTACK_DIR="/opt/utmstack-demo"
print_status "Creating UTMStack demo directory: ${UTMSTACK_DIR}"
mkdir -p ${UTMSTACK_DIR}
cd ${UTMSTACK_DIR}

# Clone UTMStack repository
print_status "Cloning UTMStack repository..."
git clone https://github.com/utmstack/UTMStack.git .
git checkout v10

# Create minimal configuration for demo
print_status "Creating minimal demo configuration..."
cat > /root/utmstack-demo.yml << EOF
main_server: $(hostname -I | awk '{print $1}')
branch: v10
password: utmstackdemo2024
data_dir: /opt/utmstack-demo/data
server_type: aio
server_name: $(hostname)
internal_key: $(openssl rand -hex 32)
EOF

# Build backend (Java)
print_status "Building backend (Java Spring Boot)..."
cd backend
mvn clean package -DskipTests -Dmaven.javadoc.skip=true
cd ..

# Build frontend (Angular)
print_status "Building frontend (Angular)..."
cd frontend
npm install
npm run build --prod
cd ..

# Build Go microservices
print_status "Building Go microservices..."
cd agent
go mod download
go build -o utmstack-agent .
cd ..

cd agent-manager
go mod download
go build -o utmstack-agent-manager .
cd ..

# Create minimal Docker Compose for demo
print_status "Creating minimal Docker Compose configuration..."
cat > docker-compose.demo.yml << EOF
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

# Create nginx configuration
cat > nginx.conf << EOF
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
            try_files \$uri \$uri/ /index.html;
        }

        location /api {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
    }
}
EOF

# Create startup script
cat > start-demo.sh << 'EOF'
#!/bin/bash
echo "Starting UTMStack Demo..."
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
echo "Waiting for services to start..."
sleep 30

echo ""
echo "UTMStack Demo is starting up!"
echo "Access the application at: http://$(hostname -I | awk '{print $1}')"
echo "Default credentials: admin / utmstackdemo2024"
echo ""
echo "To stop: docker-compose -f docker-compose.demo.yml down"
echo "To view logs: docker-compose -f docker-compose.demo.yml logs -f"
EOF

chmod +x start-demo.sh

# Create systemd service for auto-start
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
print_success "UTMStack Demo build completed successfully!"
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
echo "- Services may be slower than production"
echo "- Monitor system resources during operation"
echo ""
echo "🔧 Manual control:"
echo "- Start: cd /opt/utmstack-demo && ./start-demo.sh"
echo "- Stop: cd /opt/utmstack-demo && docker-compose -f docker-compose.demo.yml down"
echo "- Restart: cd /opt/utmstack-demo && docker-compose -f docker-compose.demo.yml restart"
echo ""
print_success "Build script completed! Ready to start UTMStack demo."
