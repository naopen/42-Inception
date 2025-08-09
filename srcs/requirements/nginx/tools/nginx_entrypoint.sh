#!/bin/bash

# Error handling
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[NGINX]${NC} $1"
}

error() {
    echo -e "${RED}[NGINX ERROR]${NC} $1" >&2
    exit 1
}

# Check if DOMAIN_NAME is set
if [ -z "$DOMAIN_NAME" ]; then
    error "DOMAIN_NAME environment variable is not set!"
fi

log "Starting NGINX for domain: ${DOMAIN_NAME}"

# Generate SSL certificate if it doesn't exist
if [ ! -f /etc/nginx/ssl/inception.crt ] || [ ! -f /etc/nginx/ssl/inception.key ]; then
    log "Generating SSL certificate for ${DOMAIN_NAME}..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=JP/ST=Tokyo/L=Tokyo/O=42School/OU=Inception/CN=${DOMAIN_NAME}"
    
    chmod 600 /etc/nginx/ssl/inception.key
    chmod 644 /etc/nginx/ssl/inception.crt
    log "SSL certificate generated successfully!"
fi

# Create NGINX configuration from template
log "Configuring NGINX..."
cat > /etc/nginx/sites-available/default << EOF
server {
    # Listen only on port 443 with SSL (requirement)
    listen 443 ssl;
    listen [::]:443 ssl;
    
    server_name ${DOMAIN_NAME} localhost;
    
    # SSL/TLS Configuration (TLSv1.2 or TLSv1.3 only as required)
    ssl_certificate /etc/nginx/ssl/inception.crt;
    ssl_certificate_key /etc/nginx/ssl/inception.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Root directory for WordPress
    root /var/www/wordpress;
    index index.php index.html index.htm;
    
    # Logging
    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;
    
    # Client body size (for file uploads)
    client_max_body_size 64M;
    
    # Main location block
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # PHP processing
    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param HTTPS on;
        
        # PHP-FPM settings
        fastcgi_intercept_errors on;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_read_timeout 300;
    }
    
    # WordPress specific rules
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
    
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    
    # Deny access to hidden files and directories
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to wp-config.php
    location ~* /wp-config.php {
        deny all;
    }
    
    # Deny access to XML-RPC
    location = /xmlrpc.php {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Allow only internal access to WordPress installation scripts
    location ~* ^/wp-admin/(install|setup-config)\.php\$ {
        deny all;
    }
    
    # Cache static files
    location ~* \.(jpg|jpeg|gif|png|css|js|ico|webp|svg|woff|woff2|ttf|eot)\$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml application/atom+xml image/svg+xml text/javascript application/vnd.ms-fontobject application/x-font-ttf font/opentype;
}

# Explicitly deny all traffic on port 80 (HTTP)
server {
    listen 80;
    listen [::]:80;
    server_name _;
    return 444; # Close connection without response
}
EOF

# Test NGINX configuration
log "Testing NGINX configuration..."
nginx -t

if [ $? -ne 0 ]; then
    error "NGINX configuration test failed!"
fi

# Start NGINX
log "Starting NGINX..."
exec nginx -g "daemon off;"
