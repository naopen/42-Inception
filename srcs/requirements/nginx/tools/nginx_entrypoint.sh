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
else
    log "SSL certificate already exists"
fi

# Create NGINX configuration from template
log "Configuring NGINX..."
cat > /etc/nginx/sites-available/default << EOF
server {
    # Listen only on port 443 with SSL (requirement)
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    
    server_name ${DOMAIN_NAME} localhost _;
    
    # SSL/TLS Configuration (TLSv1.2 or TLSv1.3 only as required)
    ssl_certificate /etc/nginx/ssl/inception.crt;
    ssl_certificate_key /etc/nginx/ssl/inception.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    
    # Root directory for WordPress
    root /var/www/wordpress;
    index index.php index.html index.htm;
    
    # Logging
    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log debug;
    
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
}

# Explicitly deny all traffic on port 80 (HTTP)
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 444; # Close connection without response
}
EOF

# Create symbolic link to enable the site
log "Enabling site configuration..."
ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Remove any other default configurations
rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true

# Test NGINX configuration
log "Testing NGINX configuration..."
nginx -t 2>&1

if [ $? -ne 0 ]; then
    error "NGINX configuration test failed!"
fi

# Create an index.html for testing
if [ ! -f /var/www/wordpress/index.html ]; then
    cat > /var/www/wordpress/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Inception - 42 Project</title>
</head>
<body>
    <h1>NGINX is working!</h1>
    <p>If you see this page, NGINX is properly configured.</p>
    <p>WordPress installation is in progress...</p>
</body>
</html>
HTML
    chown www-data:www-data /var/www/wordpress/index.html
fi

# Start NGINX in foreground
log "Starting NGINX in foreground..."
exec nginx -g "daemon off;"
