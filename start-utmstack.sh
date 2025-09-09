#!/bin/bash

# UTMStack Docker Startup Script
# This script checks prerequisites and starts all UTMStack services

set -e

echo "🚀 Starting UTMStack Docker Services..."
echo "======================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

echo "✅ Docker and Docker Compose are available"

# Check if certificates exist, generate if not
if [ ! -f "certs/utm.key" ] || [ ! -f "certs/utm.crt" ]; then
    echo "🔐 Generating SSL certificates..."
    mkdir -p certs
    
    # Generate private key
    openssl genrsa -out certs/utm.key 2048
    
    # Generate certificate signing request
    openssl req -new -key certs/utm.key -out certs/utm.csr -subj "/C=US/ST=State/L=City/O=UTMStack/CN=localhost"
    
    # Generate self-signed certificate
    openssl x509 -req -days 365 -in certs/utm.csr -signkey certs/utm.key -out certs/utm.crt
    
    # Set proper permissions
    chmod 600 certs/utm.key
    chmod 644 certs/utm.crt
    
    # Clean up CSR
    rm -f certs/utm.csr
    
    echo "✅ Certificates generated successfully"
else
    echo "✅ SSL certificates already exist"
fi

# Check available memory (OpenSearch needs at least 2GB)
TOTAL_MEM=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
TOTAL_MEM_GB=$((TOTAL_MEM / 1024 / 1024 / 1024))

if [ "$TOTAL_MEM_GB" -lt 4 ]; then
    echo "⚠️  Warning: System has less than 4GB RAM. UTMStack may not run optimally."
    echo "   Available RAM: ${TOTAL_MEM_GB}GB"
    echo "   Recommended: 8GB+ for production use"
    read -p "   Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted by user"
        exit 1
    fi
else
    echo "✅ Sufficient memory available (${TOTAL_MEM_GB}GB)"
fi

# Check if ports are available
PORTS=(3000 8080 9200 9300 50051 5432 5044 9600)
UNAVAILABLE_PORTS=()

for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        UNAVAILABLE_PORTS+=($port)
    fi
done

if [ ${#UNAVAILABLE_PORTS[@]} -ne 0 ]; then
    echo "⚠️  Warning: The following ports are already in use:"
    printf "   %s\n" "${UNAVAILABLE_PORTS[@]}"
    echo "   UTMStack may fail to start if these ports are needed."
    read -p "   Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted by user"
        exit 1
    fi
else
    echo "✅ All required ports are available"
fi

echo ""
echo "🏗️  Building and starting UTMStack services..."
echo "   This may take several minutes on first run..."

# Start services in background
docker-compose up -d --build

echo ""
echo "⏳ Waiting for services to start up..."
sleep 30

# Check service status
echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "🔍 Checking service health..."

# Check OpenSearch
if curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1; then
    echo "✅ OpenSearch is running"
else
    echo "❌ OpenSearch is not responding"
fi

# Check Logstash
if curl -s http://localhost:9600/_node/hot_threads > /dev/null 2>&1; then
    echo "✅ Logstash is running"
else
    echo "❌ Logstash is not responding"
fi

# Check Backend
if curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "✅ Backend is running"
else
    echo "❌ Backend is not responding"
fi

echo ""
echo "🎉 UTMStack services are starting up!"
echo ""
echo "📱 Access points:"
echo "   Frontend: http://localhost:3000"
echo "   Backend API: http://localhost:8080"
echo "   OpenSearch: http://localhost:9200"
echo "   Logstash: http://localhost:9600"
echo ""
echo "📋 Useful commands:"
echo "   View logs: docker-compose logs -f [service-name]"
echo "   Stop services: docker-compose down"
echo "   Restart services: docker-compose restart"
echo "   Check status: docker-compose ps"
echo ""
echo "⏰ Services may take a few more minutes to fully initialize."
echo "   Check the logs if you encounter any issues: docker-compose logs -f"
