#!/bin/bash

# Generate self-signed SSL certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=na-kannan.42.fr"

# Set appropriate permissions
chmod 600 /etc/nginx/ssl/inception.key
chmod 644 /etc/nginx/ssl/inception.crt

echo "SSL certificate generated successfully!"
