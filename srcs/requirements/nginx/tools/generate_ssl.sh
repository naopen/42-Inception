#!/bin/bash

# Use environment variable for domain name, with fallback
CERT_DOMAIN="${DOMAIN_NAME:-localhost}"

echo "Generating SSL certificate for domain: ${CERT_DOMAIN}"

# Generate self-signed SSL certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=JP/ST=Tokyo/L=Tokyo/O=42School/OU=Inception/CN=${CERT_DOMAIN}"

# Set appropriate permissions
chmod 600 /etc/nginx/ssl/inception.key
chmod 644 /etc/nginx/ssl/inception.crt

echo "SSL certificate generated successfully for ${CERT_DOMAIN}!"
