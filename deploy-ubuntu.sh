#!/bin/bash
set -e

echo "=========================================="
echo "UTMStack Ubuntu Server Deployment Script"
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
    echo "Error: sudo is not installed. Please install sudo first."
    exit 1
fi

# Check if binaries exist
if [ ! -d "bin" ] || [ -z "$(ls -A bin/ 2>/dev/null)" ]; then
    echo "Error: No binaries found in 'bin' directory."
    echo "Please run './build.sh' first to build UTMStack."
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

# Function to deploy binaries
deploy_binaries() {
    echo "Deploying UTMStack binaries..."
    
    # Copy binaries to system directories
    sudo cp bin/* /usr/local/bin/
    
    # Set executable permissions
    sudo chmod +x /usr/local/bin/utmstack-*
    
    # Verify installation
    echo "✓ Deployed binaries:"
    ls -la /usr/local/bin/utmstack-*
}

# Function to create systemd services
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

# Function to configure Nginx
configure_nginx() {
    if command_exists nginx; then
        echo "Configuring Nginx..."
        
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
        
        echo "✓ Nginx configured"
    else
        echo "⚠ Nginx not found, skipping configuration"
    fi
}

# Function to configure log rotation
configure_log_rotation() {
    echo "Configuring log rotation..."
    
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

# Function to start services
start_services() {
    echo "Starting UTMStack services..."
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    # Enable services
    sudo systemctl enable utmstack-agent
    sudo systemctl enable utmstack-agent-manager
    
    # Start services
    sudo systemctl start utmstack-agent
    sudo systemctl start utmstack-agent-manager
    
    # Wait a moment for services to start
    sleep 5
    
    # Check status
    echo "Service status:"
    sudo systemctl status utmstack-agent --no-pager -l
    echo ""
    sudo systemctl status utmstack-agent-manager --no-pager -l
    
    echo "✓ Services started"
}

# Function to verify deployment
verify_deployment() {
    echo "Verifying deployment..."
    
    # Check if processes are running
    if pgrep -f "utmstack-agent" > /dev/null; then
        echo "✓ UTMStack Agent is running"
    else
        echo "⚠ UTMStack Agent is not running"
    fi
    
    if pgrep -f "utmstack-agent-manager" > /dev/null; then
        echo "✓ UTMStack Agent Manager is running"
    else
        echo "⚠ UTMStack Agent Manager is not running"
    fi
    
    # Check listening ports
    echo "Listening ports:"
    sudo netstat -tlnp | grep utmstack || echo "No UTMStack ports found"
    
    # Check logs
    echo "Recent logs:"
    sudo journalctl -u utmstack-agent --no-pager -n 5
    echo ""
    sudo journalctl -u utmstack-agent-manager --no-pager -n 5
}

# Function to display access information
display_access_info() {
    echo ""
    echo "=========================================="
    echo "DEPLOYMENT COMPLETE!"
    echo "=========================================="
    echo ""
    echo "UTMStack has been successfully deployed on Ubuntu Server!"
    echo ""
    echo "Access Information:"
    echo "- Web Interface (Direct): http://$(hostname -I | awk '{print $1}'):8080"
    echo "- Web Interface (Nginx): http://$(hostname -I | awk '{print $1}')"
    echo "- Agent Manager API: http://$(hostname -I | awk '{print $1}'):9000"
    echo ""
    echo "Service Management:"
    echo "- Check status: sudo systemctl status utmstack-*"
    echo "- View logs: sudo journalctl -u utmstack-agent -f"
    echo "- Restart services: sudo systemctl restart utmstack-*"
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

# Main deployment function
main() {
    echo "Starting UTMStack Ubuntu Server deployment..."
    echo ""
    
    # Detect Ubuntu version
    detect_ubuntu_version
    
    # Deploy components
    deploy_binaries
    create_utmstack_user
    create_systemd_services
    configure_nginx
    configure_log_rotation
    start_services
    verify_deployment
    display_access_info
}

# Run main function
main "$@"
