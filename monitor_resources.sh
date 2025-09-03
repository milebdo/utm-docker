#!/bin/bash

# UTMStack Demo Resource Monitor
# Monitors system resources for demo environment
# Usage: ./monitor_resources.sh [interval_in_seconds]

set -e

# Default monitoring interval (5 seconds)
INTERVAL=${1:-5}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  UTMStack Demo Resource Monitor${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo "Monitoring interval: ${INTERVAL} seconds"
    echo "Press Ctrl+C to stop monitoring"
    echo ""
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Function to get memory usage
get_memory_info() {
    echo -e "${BLUE}📊 Memory Usage:${NC}"
    free -h | grep -E "Mem|Swap"
    
    # Check if memory is getting low
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ "$MEM_USAGE" -gt 90 ]; then
        print_error "Memory usage is critical: ${MEM_USAGE}%"
    elif [ "$MEM_USAGE" -gt 80 ]; then
        print_warning "Memory usage is high: ${MEM_USAGE}%"
    else
        print_success "Memory usage is normal: ${MEM_USAGE}%"
    fi
    echo ""
}

# Function to get disk usage
get_disk_info() {
    echo -e "${BLUE}💾 Disk Usage:${NC}"
    df -h | grep -E "^/dev/"
    
    # Check if disk is getting full
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 90 ]; then
        print_error "Disk usage is critical: ${DISK_USAGE}%"
    elif [ "$DISK_USAGE" -gt 80 ]; then
        print_warning "Disk usage is high: ${DISK_USAGE}%"
    else
        print_success "Disk usage is normal: ${DISK_USAGE}%"
    fi
    echo ""
}

# Function to get CPU usage
get_cpu_info() {
    echo -e "${BLUE}🖥️  CPU Usage:${NC}"
    echo "CPU Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo "CPU Cores: $(nproc)"
    echo ""
}

# Function to get Docker container status
get_docker_info() {
    echo -e "${BLUE}🐳 Docker Containers:${NC}"
    
    # Check if Docker is running
    if ! systemctl is-active --quiet docker; then
        print_error "Docker service is not running"
        echo ""
        return
    fi
    
    # Count running containers
    RUNNING_CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | wc -l)
    RUNNING_CONTAINERS=$((RUNNING_CONTAINERS - 1))  # Subtract header line
    
    if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
        print_warning "No Docker containers are running"
    else
        print_success "Running containers: ${RUNNING_CONTAINERS}"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    fi
    echo ""
}

# Function to get UTMStack service status
get_utmstack_status() {
    echo -e "${BLUE}🔒 UTMStack Service Status:${NC}"
    
    if systemctl is-active --quiet utmstack-demo; then
        print_success "UTMStack demo service is running"
        echo "Service status: $(systemctl is-active utmstack-demo)"
    else
        print_error "UTMStack demo service is not running"
        echo "Service status: $(systemctl is-active utmstack-demo)"
    fi
    
    # Check if service is enabled
    if systemctl is-enabled --quiet utmstack-demo; then
        print_success "Service is enabled for auto-start"
    else
        print_warning "Service is not enabled for auto-start"
    fi
    echo ""
}

# Function to get network connections
get_network_info() {
    echo -e "${BLUE}🌐 Network Connections:${NC}"
    
    # Check UTMStack ports
    PORTS=("80" "443" "8080" "9200" "5044" "5432")
    
    for port in "${PORTS[@]}"; do
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            print_success "Port $port is listening"
        else
            print_warning "Port $port is not listening"
        fi
    done
    echo ""
}

# Function to get system uptime and load
get_system_info() {
    echo -e "${BLUE}🖥️  System Information:${NC}"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Current time: $(date)"
    echo ""
}

# Function to check for potential issues
check_issues() {
    echo -e "${BLUE}🔍 Health Check:${NC}"
    
    # Check memory
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ "$MEM_USAGE" -gt 90 ]; then
        print_error "⚠️  CRITICAL: Memory usage is ${MEM_USAGE}%"
        echo "   Consider stopping non-essential services or restarting UTMStack"
    fi
    
    # Check disk
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 90 ]; then
        print_error "⚠️  CRITICAL: Disk usage is ${DISK_USAGE}%"
        echo "   Consider cleaning Docker images: docker system prune -a"
    fi
    
    # Check Docker
    if ! systemctl is-active --quiet docker; then
        print_error "⚠️  CRITICAL: Docker service is not running"
        echo "   Start Docker: systemctl start docker"
    fi
    
    # Check UTMStack service
    if ! systemctl is-active --quiet utmstack-demo; then
        print_error "⚠️  CRITICAL: UTMStack service is not running"
        echo "   Start service: systemctl start utmstack-demo"
    fi
    
    echo ""
}

# Function to show recommendations
show_recommendations() {
    echo -e "${BLUE}💡 Recommendations:${NC}"
    
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$MEM_USAGE" -gt 80 ]; then
        echo "• Memory usage is high - consider restarting UTMStack services"
        echo "• Monitor with: docker stats"
    fi
    
    if [ "$DISK_USAGE" -gt 80 ]; then
        echo "• Disk usage is high - clean up Docker: docker system prune -a"
        echo "• Check large files: du -sh /* | sort -hr | head -10"
    fi
    
    echo "• For production use, upgrade to: 16GB+ RAM, 150GB+ storage"
    echo "• Use official installer: utmstack.com/install"
    echo ""
}

# Main monitoring loop
main() {
    print_header
    
    while true; do
        clear
        print_header
        
        get_system_info
        get_memory_info
        get_disk_info
        get_cpu_info
        get_docker_info
        get_utmstack_status
        get_network_info
        check_issues
        show_recommendations
        
        echo -e "${BLUE}Next update in ${INTERVAL} seconds... (Press Ctrl+C to stop)${NC}"
        sleep "$INTERVAL"
    done
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${GREEN}Monitoring stopped.${NC}"; exit 0' INT

# Check if script is run as root
if [[ $EUID -eq 0 ]]; then
    main
else
    print_error "This script should be run as root for full access"
    print_status "Running with limited privileges..."
    main
fi
