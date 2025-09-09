#!/bin/bash

# UTMStack Docker Stop Script

echo "🛑 Stopping UTMStack Docker Services..."
echo "======================================"

# Stop all services
docker-compose down

echo "✅ All UTMStack services have been stopped"
echo ""
echo "📋 To start services again, run: ./start-utmstack.sh"
echo "📋 To remove all data and volumes, run: docker-compose down -v"
