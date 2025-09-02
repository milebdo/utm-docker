#!/bin/bash
set -e

echo "=========================================="
echo "UTMStack Ubuntu Server Installation Script"
echo "=========================================="
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root"
   echo "Please run as a regular user with sudo privileges"
   exit 1
fi

# Check if sudo is available
if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: sudo is not installed. Please install sudo first:"
    echo "  su -"
    echo "  apt update && apt install -y sudo"
    echo "  usermod -aG sudo $USER"
    echo "  exit"
    echo "Then log back in and run this script again."
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect Ubuntu version
detect_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            echo "Detected Ubuntu Server $VERSION_ID"
            return 0
        else
            echo "Error: This script is designed for Ubuntu Server only."
            echo "Detected OS: $ID $VERSION_ID"
            exit 1
        fi
    else
        echo "Error: Could not detect OS version."
        echo "This script is designed for Ubuntu Server only."
        exit 1
    fi
}

# Function to update system
update_system() {
    echo "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    echo "✓ System updated"
}

# Function to install essential build tools
install_build_tools() {
    echo "Installing essential build tools and dependencies..."
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
    echo "✓ Build tools installed"
}

# Function to install Go 1.23+
install_go() {
    if ! command_exists go || ! go version | grep -q "go1.2[3-9]\|go1.[3-9][0-9]"; then
        echo "Installing Go 1.23+..."
        GO_VERSION="1.23.0"
        GO_ARCH="linux-amd64"
        GO_TAR="go${GO_VERSION}.${GO_ARCH}.tar.gz"
        
        # Download and install Go
        wget -q "https://go.dev/dl/${GO_TAR}" -O /tmp/${GO_TAR}
        sudo tar -C /usr/local -xzf /tmp/${GO_TAR}
        rm /tmp/${GO_TAR}
        
        # Add Go to PATH
        if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
            export PATH=$PATH:/usr/local/go/bin
        fi
        
        echo "✓ Installed Go ${GO_VERSION}"
    else
        echo "✓ Go is already installed and up to date"
    fi
}

# Function to install Node.js 16.x
install_nodejs() {
    if ! command_exists node || ! node --version | grep -q "v16"; then
        echo "Installing Node.js 16.x for Angular 7 compatibility..."
        
        # Remove existing Node.js if present
        sudo apt remove -y nodejs npm
        sudo apt autoremove -y
        
        # Install Node.js 16.x from NodeSource
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt install -y nodejs
        
        # Verify installation
        NODE_VERSION=$(node --version)
        NPM_VERSION=$(npm --version)
        echo "✓ Installed Node.js $NODE_VERSION and npm $NPM_VERSION"
    else
        echo "✓ Node.js 16.x is already installed"
    fi
}

# Function to install Docker
install_docker() {
    if ! command_exists docker; then
        echo "Installing Docker..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        sudo usermod -aG docker $USER
        echo "✓ Installed Docker"
        echo "⚠ Note: You may need to log out and back in for Docker group permissions to take effect"
    else
        echo "✓ Docker is already installed"
    fi
}

# Function to install additional system dependencies
install_system_deps() {
    echo "Installing additional system dependencies..."
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
    echo "✓ System dependencies installed"
}

# Function to configure firewall
configure_firewall() {
    echo "Configuring firewall..."
    sudo ufw --force enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 8080/tcp
    sudo ufw allow 9000/tcp
    sudo ufw allow 9200/tcp
    sudo ufw allow 9300/tcp
    sudo ufw allow 5601/tcp
    sudo ufw allow 5432/tcp
    sudo ufw allow 6379/tcp
    echo "✓ Firewall configured"
}

# Function to create UTMStack user and directories
create_utmstack_user() {
    if ! id "utmstack" &>/dev/null; then
        echo "Creating UTMStack user..."
        sudo useradd -m -s /bin/bash utmstack
        sudo usermod -aG sudo utmstack
        echo "✓ Created UTMStack user"
    else
        echo "✓ UTMStack user already exists"
    fi
    
    # Create UTMStack directories
    sudo mkdir -p /opt/utmstack
    sudo mkdir -p /var/log/utmstack
    sudo mkdir -p /etc/utmstack
    sudo chown -R utmstack:utmstack /opt/utmstack
    sudo chown -R utmstack:utmstack /var/log/utmstack
    sudo chown -R utmstack:utmstack /etc/utmstack
    
    echo "✓ Created UTMStack directories"
}

# Function to install Python dependencies
install_python_deps() {
    echo "Installing Python dependencies..."
    if command_exists pip; then
        pip install --user --upgrade pip
        pip install --user virtualenv
    elif command_exists pip3; then
        pip3 install --user --upgrade pip
        pip3 install --user virtualenv
    fi
    echo "✓ Python dependencies installed"
}

# Function to create systemd service files
create_systemd_services() {
    echo "Creating systemd service files..."
    
    # Create UTMStack Agent service
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

    # Create UTMStack Agent Manager service
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

    echo "✓ Systemd service files created"
}

# Function to create Nginx configuration
create_nginx_config() {
    echo "Creating Nginx configuration..."
    
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
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    
    echo "✓ Nginx configured"
}

# Function to create log rotation
create_log_rotation() {
    echo "Creating log rotation configuration..."
    
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

    echo "✓ Log rotation configured"
}

# Main installation function
main() {
    echo "Starting UTMStack Ubuntu Server installation..."
    echo ""
    
    # Detect Ubuntu version
    detect_ubuntu_version
    
    # Update system
    update_system
    
    # Install dependencies
    install_build_tools
    install_go
    install_nodejs
    install_docker
    install_system_deps
    install_python_deps
    
    # Configure system
    configure_firewall
    create_utmstack_user
    create_systemd_services
    create_nginx_config
    create_log_rotation
    
    echo ""
    echo "=========================================="
    echo "INSTALLATION COMPLETE!"
    echo "=========================================="
    echo ""
    echo "Your Ubuntu Server is now ready for UTMStack!"
    echo ""
    echo "Next steps:"
    echo "1. Build UTMStack: ./build.sh"
    echo "2. Copy binaries: sudo cp bin/* /usr/local/bin/"
    echo "3. Set permissions: sudo chmod +x /usr/local/bin/utmstack-*"
    echo "4. Start services:"
    echo "   sudo systemctl daemon-reload"
    echo "   sudo systemctl enable utmstack-agent"
    echo "   sudo systemctl enable utmstack-agent-manager"
    echo "   sudo systemctl start utmstack-agent"
    echo "   sudo systemctl start utmstack-agent-manager"
    echo ""
    echo "5. Check status: sudo systemctl status utmstack-*"
    echo "6. Access web interface: http://your-server-ip"
    echo ""
    echo "For production deployment, consider:"
    echo "- Setting up SSL certificates with Let's Encrypt"
    echo "- Configuring monitoring and alerting"
    echo "- Setting up backup strategies"
    echo "- Configuring log aggregation"
    echo ""
    echo "Documentation: https://docs.utmstack.com"
    echo "Support: https://github.com/utmstack/UTMStack/issues"
    echo ""
    echo "=========================================="
}

# Run main function
main "$@"
