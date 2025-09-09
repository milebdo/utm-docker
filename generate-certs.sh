#!/bin/bash

# Create certificates directory
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

echo "Certificates generated successfully in certs/ directory"
echo "Files created:"
echo "  - utm.key (private key)"
echo "  - utm.crt (certificate)"
echo "  - utm.csr (certificate signing request - can be deleted)"
