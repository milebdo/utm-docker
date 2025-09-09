# UTMStack Docker Setup

This document explains how to run UTMStack using Docker Compose with all required services.

## Overview

The updated `docker-compose.yaml` includes all necessary services for UTMStack:

- **OpenSearch**: Search and analytics engine (Elasticsearch fork)
- **Logstash**: Log processing and pipeline management
- **PostgreSQL**: Database for UTMStack metadata
- **Agent Manager**: gRPC service for managing UTMStack agents
- **Backend**: Java Spring Boot application
- **Frontend**: Angular web interface

## Prerequisites

- Docker and Docker Compose installed
- At least 8GB RAM available for all services
- At least 20GB disk space

## Quick Start

1. **Clone the repository** (if not already done):
   ```bash
   git clone https://github.com/utmstack/UTMStack.git
   cd UTMStack
   ```

2. **Generate SSL certificates** (required for Agent Manager):
   ```bash
   mkdir -p certs
   openssl genrsa -out certs/utm.key 2048
   openssl req -new -key certs/utm.key -out certs/utm.csr -subj "/C=US/ST=State/L=City/O=UTMStack/CN=localhost"
   openssl x509 -req -days 365 -in certs/utm.csr -signkey certs/utm.key -out certs/utm.crt
   chmod 600 certs/utm.key
   chmod 644 certs/utm.crt
   rm certs/utm.csr
   ```

3. **Start all services**:
   ```bash
   docker-compose up -d
   ```

4. **Check service status**:
   ```bash
   docker-compose ps
   ```

5. **View logs**:
   ```bash
   docker-compose logs -f [service-name]
   ```

## Service Details

### OpenSearch (Port 9200)
- **Purpose**: Stores and indexes log data
- **Health Check**: http://localhost:9200/_cluster/health
- **Default Credentials**: admin/admin (if security enabled)
- **Image**: opensearchproject/opensearch:2.11.0

### Logstash (Ports 5044, 9600)
- **Purpose**: Processes and transforms log data
- **Inputs**: HTTP (9600), Syslog (5044), TCP (5000)
- **Output**: OpenSearch
- **Health Check**: http://localhost:9600/_node/hot_threads

### PostgreSQL (Port 5432)
- **Purpose**: Stores UTMStack application data
- **Database**: utmstack
- **Credentials**: utm/utmstack

### Agent Manager (Port 50051)
- **Purpose**: Manages UTMStack agents via gRPC
- **Protocol**: gRPC with TLS
- **Dependencies**: PostgreSQL

### Backend (Port 8080)
- **Purpose**: REST API and business logic
- **Dependencies**: PostgreSQL, OpenSearch, Agent Manager, Logstash
- **Health Check**: http://localhost:8080/actuator/health

### Frontend (Port 3000)
- **Purpose**: Web user interface
- **Dependencies**: Backend
- **Access**: http://localhost:3000
- **Internal Port**: 80 (nginx)

## Environment Variables

The backend service requires these environment variables (already configured in docker-compose.yaml):

- **Database**: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`
- **OpenSearch**: `ELASTICSEARCH_HOST`, `ELASTICSEARCH_PORT`
- **Agent Manager**: `GRPC_AGENT_MANAGER_HOST`, `GRPC_AGENT_MANAGER_PORT`
- **Security**: `INTERNAL_KEY`, `ENCRYPTION_KEY`
- **Logstash**: `LOGSTASH_URL`
- **Server**: `SERVER_NAME`

## Troubleshooting

### Common Issues

1. **Backend fails to start with missing environment variables**:
   - Ensure all services are running: `docker-compose ps`
   - Check service dependencies in docker-compose.yaml

2. **OpenSearch won't start**:
   - Ensure sufficient memory (at least 2GB available)
   - Check ulimits configuration

3. **Certificate errors**:
   - Regenerate certificates using the commands above
   - Ensure proper file permissions (600 for key, 644 for cert)

4. **Port conflicts**:
   - Check if ports 3000, 8080, 9200, 9300, 50051, 5432 are available
   - Modify ports in docker-compose.yaml if needed

### Logs and Debugging

- **View all logs**: `docker-compose logs -f`
- **View specific service**: `docker-compose logs -f backend`
- **Check service status**: `docker-compose ps`
- **Restart service**: `docker-compose restart [service-name]`

## Production Considerations

1. **Security**:
   - Change default passwords
   - Use proper SSL certificates
   - Enable OpenSearch security features
   - Restrict network access

2. **Performance**:
   - Adjust memory settings for OpenSearch and Logstash
   - Use persistent volumes for data
   - Consider horizontal scaling for large deployments

3. **Monitoring**:
   - Set up health checks
   - Monitor resource usage
   - Configure log rotation

## Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: destroys data)
docker-compose down -v

# Stop specific service
docker-compose stop [service-name]
```

## Updating

1. **Pull latest code**:
   ```bash
   git pull origin main
   ```

2. **Rebuild and restart**:
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

## Support

For issues and questions:
- Check the logs: `docker-compose logs -f`
- Review this documentation
- Check the main UTMStack documentation
- Open an issue on GitHub
