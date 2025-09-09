#!/bin/bash

# UTMStack Automated Installation Script for Ubuntu Server
# This script automates the complete deployment of UTMStack

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
UTMSTACK_DIR="/opt/UTMStack"
REPO_URL="https://github.com/utmstack/UTMStack.git"
NODE_VERSION="18"

# Function to print colored output
print_status() {
    if [ $2 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
    fi
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root. This script will run as root user."
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to check system requirements
check_requirements() {
    print_info "Checking system requirements..."
    
    # Check Ubuntu version
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$VERSION" == *"22.04"* ]]; then
            print_status "Ubuntu 22.04 LTS detected" 0
        else
            print_warning "Ubuntu 22.04 LTS recommended, found: $VERSION"
        fi
    fi
    
    # Check CPU cores
    CPU_CORES=$(nproc)
    if [ $CPU_CORES -ge 4 ]; then
        print_status "CPU cores: $CPU_CORES (OK)" 0
    else
        print_warning "Minimum 4 cores recommended, found: $CPU_CORES"
    fi
    
    # Check RAM
    RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [ $RAM_GB -ge 16 ]; then
        print_status "RAM: ${RAM_GB}GB (OK)" 0
    else
        print_warning "Minimum 16GB RAM recommended, found: ${RAM_GB}GB"
    fi
    
    # Check disk space
    DISK_GB=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $DISK_GB -ge 150 ]; then
        print_status "Available disk space: ${DISK_GB}GB (OK)" 0
    else
        print_warning "Minimum 150GB disk space recommended, found: ${DISK_GB}GB"
    fi
}

# Function to update system packages
update_system() {
    print_info "Updating system packages..."
    apt update && apt upgrade -y
    print_status "System packages updated" 0
}

# Function to install required packages
install_packages() {
    print_info "Installing required packages..."
    apt install -y curl wget git build-essential apt-transport-https ca-certificates gnupg lsb-release
    print_status "Required packages installed" 0
}

# Function to install Docker
install_docker() {
    print_info "Installing Docker Engine..."
    
    # Remove old Docker versions
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add current user to docker group
    usermod -aG docker $USER
    
    # Enable Docker to start on boot
    systemctl enable docker
    systemctl start docker
    
    print_status "Docker Engine installed and started" 0
}

# Function to install Docker Compose
install_docker_compose() {
    print_info "Installing Docker Compose..."
    
    # Check if docker compose plugin is available
    if docker compose version &> /dev/null; then
        print_status "Docker Compose plugin already available" 0
        return 0
    fi
    
    # Install standalone Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    print_status "Docker Compose installed" 0
}

# Function to install Node.js
install_nodejs() {
    print_info "Installing Node.js $NODE_VERSION..."
    
    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    apt install -y nodejs
    
    print_status "Node.js $(node --version) installed" 0
}

# Function to clone UTMStack repository
clone_repository() {
    print_info "Cloning UTMStack repository..."
    
    # Create directory if it doesn't exist
    mkdir -p /opt
    
    # Remove existing directory if it exists
    if [ -d "$UTMSTACK_DIR" ]; then
        print_warning "Removing existing UTMStack directory..."
        rm -rf "$UTMSTACK_DIR"
    fi
    
    # Clone repository
    git clone "$REPO_URL" "$UTMSTACK_DIR"
    chown -R $USER:$USER "$UTMSTACK_DIR"
    
    print_status "UTMStack repository cloned to $UTMSTACK_DIR" 0
}

# Function to configure frontend environment
configure_frontend() {
    print_info "Configuring frontend environment..."
    
    cd "$UTMSTACK_DIR/frontend"
    
    # Update environment.prod.ts
    cat > src/environments/environment.prod.ts << 'EOF'
export const environment = {
  production: true,
  SERVER_API_URL: 'http://localhost:8080/',
  WEBSOCKET_URL: 'ws://localhost:8080/',
  SESSION_AUTH_TOKEN: window.location.host.split(':')[0].toLocaleUpperCase(),
  SERVER_API_CONTEXT: '',
  BUILD_TIMESTAMP: new Date().getTime(),
  DEBUG_INFO_ENABLED: true,
  VERSION: '0.0.1'
};
EOF
    
    # Update angular.json to fix build issues
    print_info "Updating Angular configuration..."
    
    # Create backup of angular.json
    cp angular.json angular.json.backup
    
    # Use jq to update angular.json (if available) or use sed
    if command -v jq &> /dev/null; then
        # Use jq to update the configuration
        jq '.projects.utm-stack.architect.build.configurations.production.optimization = false' angular.json > angular.json.tmp
        jq '.projects.utm-stack.architect.build.configurations.production.buildOptimizer = false' angular.json.tmp > angular.json.tmp2
        jq '.projects.utm-stack.architect.build.options.scripts = ["node_modules/jquery/dist/jquery.min.js"]' angular.json.tmp2 > angular.json
        rm angular.json.tmp angular.json.tmp2
    else
        # Use sed as fallback
        sed -i 's/"optimization": true/"optimization": false/g' angular.json
        sed -i 's/"buildOptimizer": true/"buildOptimizer": false/g' angular.json
        # Note: Scripts array update would need more complex sed commands
    fi
    
    # Update tsconfig.json
    print_info "Updating TypeScript configuration..."
    sed -i 's/"target": "es5"/"target": "es2015"/g' tsconfig.json
    sed -i 's/"module": "commonjs"/"module": "es2015"/g' tsconfig.json
    
    print_status "Frontend configuration updated" 0
}

# Function to build frontend
build_frontend() {
    print_info "Building frontend..."
    
    cd "$UTMSTACK_DIR/frontend"
    
    # Install dependencies
    print_info "Installing frontend dependencies..."
    npm install
    
    # Build with legacy OpenSSL provider
    print_info "Building frontend with legacy OpenSSL provider..."
    export NODE_OPTIONS="--openssl-legacy-provider"
    npm run build
    
    print_status "Frontend built successfully" 0
}

# Function to configure nginx
configure_nginx() {
    print_info "Configuring Nginx..."
    
    # Update nginx configuration with cache-busting headers
    cat > "$UTMSTACK_DIR/frontend/nginx/default.conf" << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

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
}
EOF
    
    print_status "Nginx configuration updated" 0
}

# Function to deploy with Docker Compose
deploy_services() {
    print_info "Deploying UTMStack services..."
    
    cd "$UTMSTACK_DIR"
    
    # Build and start services
    print_info "Building and starting Docker containers..."
    docker-compose up -d --build
    
    # Wait for services to start
    print_info "Waiting for services to start..."
    sleep 30
    
    # Check service status
    print_info "Checking service status..."
    docker-compose ps
    
    print_status "UTMStack services deployed" 0
}

# Function to configure firewall
configure_firewall() {
    print_info "Configuring firewall..."
    
    # Install UFW if not installed
    apt install -y ufw
    
    # Configure firewall rules
    ufw allow 22/tcp    # SSH
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    ufw allow 3000/tcp  # UTMStack Frontend
    ufw allow 8080/tcp  # UTMStack Backend
    
    # Enable firewall
    ufw --force enable
    
    print_status "Firewall configured" 0
}

# Function to verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    # Wait a bit more for services to fully start
    sleep 10
    
    # Check if services are accessible
    local all_ok=true
    
    # Check frontend
    if curl -s http://localhost:3000 &> /dev/null; then
        print_status "Frontend (port 3000) is accessible" 0
    else
        print_status "Frontend (port 3000) is not accessible" 1
        all_ok=false
    fi
    
    # Check backend
    if curl -s http://localhost:8080/api/ping &> /dev/null; then
        print_status "Backend API (port 8080) is accessible" 0
    else
        print_status "Backend API (port 8080) is not accessible" 1
        all_ok=false
    fi
    
    # Check database
    if docker-compose -f "$UTMSTACK_DIR/docker-compose.yaml" exec -T db pg_isready -U utm &> /dev/null; then
        print_status "Database is accessible" 0
    else
        print_status "Database is not accessible" 1
        all_ok=false
    fi
    
    # Check OpenSearch
    if curl -s http://localhost:9200 &> /dev/null; then
        print_status "OpenSearch (port 9200) is accessible" 0
    else
        print_status "OpenSearch (port 9200) is not accessible" 1
        all_ok=false
    fi
    
    if [ "$all_ok" = true ]; then
        print_status "All services are running correctly" 0
        return 0
    else
        print_error "Some services are not accessible. Check logs with: docker-compose logs"
        return 1
    fi
}

# Function to display final information
display_final_info() {
    echo
    echo "=========================================="
    echo -e "${GREEN}UTMStack Installation Complete!${NC}"
    echo "=========================================="
    echo
    echo "Access Information:"
    echo "  URL: http://$(hostname -I | awk '{print $1}'):3000"
    echo "  Username: admin"
    echo "  Password: utmstack"
    echo
    echo "Service Status:"
    echo "  Frontend: http://localhost:3000"
    echo "  Backend API: http://localhost:8080"
    echo "  OpenSearch: http://localhost:9200"
    echo
    echo "Useful Commands:"
    echo "  Check status: docker-compose -f $UTMSTACK_DIR/docker-compose.yaml ps"
    echo "  View logs: docker-compose -f $UTMSTACK_DIR/docker-compose.yaml logs -f"
    echo "  Restart services: docker-compose -f $UTMSTACK_DIR/docker-compose.yaml restart"
    echo "  Stop services: docker-compose -f $UTMSTACK_DIR/docker-compose.yaml down"
    echo
    echo "Troubleshooting:"
    echo "  Run: $UTMSTACK_DIR/troubleshoot.sh"
    echo
    echo "Security Recommendations:"
    echo "  1. Change default admin password immediately"
    echo "  2. Configure SSL/HTTPS for production use"
    echo "  3. Set up regular backups"
    echo "  4. Monitor system resources"
    echo
}

# Main installation function
main() {
    echo "=========================================="
    echo -e "${BLUE}UTMStack Automated Installation Script${NC}"
    echo "=========================================="
    echo
    
    # Check if running as root
    check_root
    
    # Check system requirements
    check_requirements
    
    # Ask for confirmation
    echo
    print_warning "This script will install UTMStack on your system."
    print_warning "It will install Docker, Node.js, and configure all services."
    echo
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    # Installation steps
    update_system
    install_packages
    install_docker
    install_docker_compose
    install_nodejs
    clone_repository
    configure_frontend
    build_frontend
    configure_nginx
    deploy_services
    configure_firewall
    
    # Verify installation
    if verify_installation; then
        display_final_info
    else
        print_error "Installation completed but some services may not be running correctly."
        print_info "Check logs with: docker-compose -f $UTMSTACK_DIR/docker-compose.yaml logs"
        print_info "Run troubleshooting script: $UTMSTACK_DIR/troubleshoot.sh"
        exit 1
    fi
}

# Run main function
main "$@"
