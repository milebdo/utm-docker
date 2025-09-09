#!/bin/bash

# UTMStack Troubleshooting Script
# This script helps diagnose common deployment issues

echo "=========================================="
echo "UTMStack Troubleshooting Script"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $2 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "Checking system requirements..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. Consider running as regular user with sudo privileges."
fi

# Check Ubuntu version
echo -n "Ubuntu version: "
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$VERSION"
    if [[ "$VERSION" == *"22.04"* ]]; then
        print_status "Ubuntu 22.04 LTS detected" 0
    else
        print_warning "Ubuntu 22.04 LTS recommended, found: $VERSION"
    fi
else
    print_status "Cannot determine Ubuntu version" 1
fi

# Check system resources
echo -e "\nChecking system resources..."

# Check CPU cores
CPU_CORES=$(nproc)
echo -n "CPU cores: $CPU_CORES "
if [ $CPU_CORES -ge 4 ]; then
    print_status "" 0
else
    print_warning "Minimum 4 cores recommended"
fi

# Check RAM
RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
echo -n "RAM: ${RAM_GB}GB "
if [ $RAM_GB -ge 16 ]; then
    print_status "" 0
else
    print_warning "Minimum 16GB RAM recommended"
fi

# Check disk space
DISK_GB=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
echo -n "Available disk space: ${DISK_GB}GB "
if [ $DISK_GB -ge 150 ]; then
    print_status "" 0
else
    print_warning "Minimum 150GB disk space recommended"
fi

# Check Docker installation
echo -e "\nChecking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo -n "Docker version: $DOCKER_VERSION "
    print_status "" 0
    
    # Check if Docker is running
    if docker info &> /dev/null; then
        print_status "Docker daemon is running" 0
    else
        print_status "Docker daemon is not running" 1
        echo "  Try: sudo systemctl start docker"
    fi
else
    print_status "Docker is not installed" 1
fi

# Check Docker Compose
echo -e "\nChecking Docker Compose..."
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
    echo -n "Docker Compose version: $COMPOSE_VERSION "
    print_status "" 0
elif docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version --short)
    echo -n "Docker Compose (plugin) version: $COMPOSE_VERSION "
    print_status "" 0
else
    print_status "Docker Compose is not installed" 1
fi

# Check Node.js
echo -e "\nChecking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version | sed 's/v//')
    echo -n "Node.js version: $NODE_VERSION "
    if [[ "$NODE_VERSION" == 18.* ]] || [[ "$NODE_VERSION" == 20.* ]]; then
        print_status "" 0
    else
        print_warning "Node.js 18+ recommended"
    fi
else
    print_status "Node.js is not installed" 1
fi

# Check if UTMStack directory exists
echo -e "\nChecking UTMStack installation..."
if [ -d "/opt/UTMStack" ]; then
    print_status "UTMStack directory found" 0
    cd /opt/UTMStack
    
    # Check if docker-compose.yaml exists
    if [ -f "docker-compose.yaml" ]; then
        print_status "docker-compose.yaml found" 0
    else
        print_status "docker-compose.yaml not found" 1
    fi
    
    # Check if frontend directory exists
    if [ -d "frontend" ]; then
        print_status "Frontend directory found" 0
        
        # Check if frontend is built
        if [ -d "frontend/dist/utm-stack" ]; then
            print_status "Frontend build directory found" 0
        else
            print_status "Frontend not built" 1
            echo "  Run: cd frontend && npm run build"
        fi
    else
        print_status "Frontend directory not found" 1
    fi
else
    print_status "UTMStack directory not found" 1
    echo "  Expected location: /opt/UTMStack"
fi

# Check running containers
echo -e "\nChecking UTMStack containers..."
if [ -f "/opt/UTMStack/docker-compose.yaml" ]; then
    cd /opt/UTMStack
    
    # Check if containers are running
    RUNNING_CONTAINERS=$(docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l)
    TOTAL_CONTAINERS=$(docker-compose ps --services 2>/dev/null | wc -l)
    
    echo -n "Running containers: $RUNNING_CONTAINERS/$TOTAL_CONTAINERS "
    if [ $RUNNING_CONTAINERS -eq $TOTAL_CONTAINERS ] && [ $TOTAL_CONTAINERS -gt 0 ]; then
        print_status "" 0
    else
        print_status "" 1
        echo "  Check: docker-compose ps"
    fi
    
    # Check specific services
    echo -e "\nChecking individual services..."
    
    # Frontend
    if curl -s http://localhost:3000 &> /dev/null; then
        print_status "Frontend (port 3000) is accessible" 0
    else
        print_status "Frontend (port 3000) is not accessible" 1
    fi
    
    # Backend
    if curl -s http://localhost:8080/api/ping &> /dev/null; then
        print_status "Backend API (port 8080) is accessible" 0
    else
        print_status "Backend API (port 8080) is not accessible" 1
    fi
    
    # Database
    if docker-compose exec -T db pg_isready -U utm &> /dev/null; then
        print_status "Database is accessible" 0
    else
        print_status "Database is not accessible" 1
    fi
    
    # OpenSearch
    if curl -s http://localhost:9200 &> /dev/null; then
        print_status "OpenSearch (port 9200) is accessible" 0
    else
        print_status "OpenSearch (port 9200) is not accessible" 1
    fi
fi

# Check network connectivity
echo -e "\nChecking network connectivity..."
if ping -c 1 8.8.8.8 &> /dev/null; then
    print_status "Internet connectivity" 0
else
    print_status "No internet connectivity" 1
fi

# Check firewall status
echo -e "\nChecking firewall..."
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(ufw status | head -1)
    echo "UFW status: $UFW_STATUS"
    
    # Check if required ports are open
    REQUIRED_PORTS=(22 80 443 3000 8080 9200)
    for port in "${REQUIRED_PORTS[@]}"; do
        if ufw status | grep -q "$port"; then
            print_status "Port $port is configured" 0
        else
            print_warning "Port $port may not be open"
        fi
    done
else
    print_warning "UFW not installed or not configured"
fi

# Check logs for errors
echo -e "\nChecking recent logs for errors..."
if [ -f "/opt/UTMStack/docker-compose.yaml" ]; then
    cd /opt/UTMStack
    
    echo "Recent backend errors:"
    docker-compose logs --tail=10 backend 2>/dev/null | grep -i error || echo "  No recent backend errors"
    
    echo "Recent frontend errors:"
    docker-compose logs --tail=10 frontend 2>/dev/null | grep -i error || echo "  No recent frontend errors"
    
    echo "Recent database errors:"
    docker-compose logs --tail=10 db 2>/dev/null | grep -i error || echo "  No recent database errors"
fi

echo -e "\n=========================================="
echo "Troubleshooting complete!"
echo "=========================================="

# Provide recommendations
echo -e "\nRecommendations:"
echo "1. If containers are not running: docker-compose up -d --build"
echo "2. If frontend shows white page: check browser console for errors"
echo "3. If login form doesn't appear: verify SERVER_API_URL in environment.prod.ts"
echo "4. If API errors occur: check backend logs with 'docker-compose logs backend'"
echo "5. For detailed logs: docker-compose logs -f [service-name]"

echo -e "\nDefault login credentials:"
echo "Username: admin"
echo "Password: utmstack"
echo "URL: http://your-server-ip:3000"
