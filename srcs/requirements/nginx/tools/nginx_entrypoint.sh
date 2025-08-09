#!/bin/bash

# Error handling
set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[NGINX]${NC} $1"
}

# Generate SSL certificate if it doesn't exist
if [ ! -f /etc/nginx/ssl/inception.crt ] || [ ! -f /etc/nginx/ssl/inception.key ]; then
    log "Generating SSL certificate..."
    /usr/local/bin/generate_ssl.sh
fi

# Replace environment variables in NGINX configuration
log "Configuring NGINX with domain: ${DOMAIN_NAME}"
sed -i "s/\${DOMAIN_NAME}/${DOMAIN_NAME}/g" /etc/nginx/sites-available/default

# Test NGINX configuration
log "Testing NGINX configuration..."
nginx -t

# Start NGINX
log "Starting NGINX..."
exec nginx -g "daemon off;"
