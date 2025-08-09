#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to ensure PHP-FPM starts even if setup fails
start_php_fpm() {
    log "Ensuring PHP-FPM directory exists..."
    mkdir -p /run/php
    chown www-data:www-data /run/php
    
    log "Starting PHP-FPM..."
    exec php-fpm7.4 -F
}

# Trap to ensure PHP-FPM starts on any exit
trap start_php_fpm EXIT

# Wait for MariaDB to be ready
log "Waiting for MariaDB to be ready..."
max_retries=30
retry_count=0

while [ $retry_count -lt $max_retries ]; do
    if mysqladmin ping -h"${WP_DB_HOST%%:*}" -u"${WP_DB_USER}" -p"${WP_DB_PASSWORD}" --silent 2>/dev/null; then
        log "MariaDB is ready!"
        break
    fi
    retry_count=$((retry_count + 1))
    if [ $retry_count -eq $max_retries ]; then
        error "MariaDB did not become ready in time"
        # Start PHP-FPM anyway
        start_php_fpm
    fi
    sleep 2
done

# Create WordPress directory if it doesn't exist
mkdir -p /var/www/wordpress
cd /var/www/wordpress

# Check if WordPress is already installed and working
if [ -f /var/www/wordpress/wp-config.php ]; then
    log "wp-config.php exists, checking WordPress installation..."
    
    # Try to verify the installation
    if wp core is-installed --allow-root --path=/var/www/wordpress 2>/dev/null; then
        log "WordPress is already installed and configured."
        
        # Ensure correct permissions
        chown -R www-data:www-data /var/www/wordpress
        find /var/www/wordpress -type d -exec chmod 755 {} \;
        find /var/www/wordpress -type f -exec chmod 644 {} \;
        
        # Start PHP-FPM
        start_php_fpm
    fi
fi

log "Starting WordPress installation and configuration..."

# Download WordPress if not exists
if [ ! -f /var/www/wordpress/index.php ]; then
    log "Downloading WordPress core files..."
    wp core download \
        --allow-root \
        --path=/var/www/wordpress \
        --locale=en_US
fi

# Create wp-config.php if it doesn't exist
if [ ! -f /var/www/wordpress/wp-config.php ]; then
    log "Creating wp-config.php..."
    
    # Generate salts
    AUTH_KEY=$(openssl rand -base64 32)
    SECURE_AUTH_KEY=$(openssl rand -base64 32)
    LOGGED_IN_KEY=$(openssl rand -base64 32)
    NONCE_KEY=$(openssl rand -base64 32)
    AUTH_SALT=$(openssl rand -base64 32)
    SECURE_AUTH_SALT=$(openssl rand -base64 32)
    LOGGED_IN_SALT=$(openssl rand -base64 32)
    NONCE_SALT=$(openssl rand -base64 32)
    
    cat > /var/www/wordpress/wp-config.php << EOF
<?php
// Database settings
define( 'DB_NAME', '${WP_DB_NAME}' );
define( 'DB_USER', '${WP_DB_USER}' );
define( 'DB_PASSWORD', '${WP_DB_PASSWORD}' );
define( 'DB_HOST', '${WP_DB_HOST}' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

// Authentication keys and salts
define( 'AUTH_KEY',         '${AUTH_KEY}' );
define( 'SECURE_AUTH_KEY',  '${SECURE_AUTH_KEY}' );
define( 'LOGGED_IN_KEY',    '${LOGGED_IN_KEY}' );
define( 'NONCE_KEY',        '${NONCE_KEY}' );
define( 'AUTH_SALT',        '${AUTH_SALT}' );
define( 'SECURE_AUTH_SALT', '${SECURE_AUTH_SALT}' );
define( 'LOGGED_IN_SALT',   '${LOGGED_IN_SALT}' );
define( 'NONCE_SALT',       '${NONCE_SALT}' );

// Database table prefix
\$table_prefix = 'wp_';

// WordPress debugging
define( 'WP_DEBUG', false );

// Site URL settings
define( 'WP_HOME', 'https://${DOMAIN_NAME}' );
define( 'WP_SITEURL', 'https://${DOMAIN_NAME}' );

// Force SSL
define( 'FORCE_SSL_ADMIN', true );

// Memory limits
define( 'WP_MEMORY_LIMIT', '128M' );

// Disable file editing
define( 'DISALLOW_FILE_EDIT', true );

// Absolute path to WordPress
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

// WordPress settings
require_once ABSPATH . 'wp-settings.php';
EOF
    
    log "wp-config.php created successfully"
fi

# Set correct permissions before installation
log "Setting initial permissions..."
chown -R www-data:www-data /var/www/wordpress
chmod 755 /var/www/wordpress
chmod 644 /var/www/wordpress/wp-config.php

# Check if WordPress needs to be installed
if ! wp core is-installed --allow-root --path=/var/www/wordpress 2>/dev/null; then
    log "Installing WordPress..."
    
    # Use a simpler installation approach with timeout
    timeout 30 wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception - 42 Project" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root \
        --path=/var/www/wordpress 2>&1 | tee /tmp/wp_install.log
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log "WordPress core installation completed"
        
        # Create additional user
        log "Creating additional user..."
        wp user create \
            "${WP_USER}" \
            "${WP_USER_EMAIL}" \
            --user_pass="${WP_USER_PASSWORD}" \
            --role=author \
            --allow-root \
            --path=/var/www/wordpress 2>/dev/null || warning "User might already exist"
        
        # Basic configuration
        wp option update timezone_string 'Asia/Tokyo' --allow-root --path=/var/www/wordpress 2>/dev/null
        wp rewrite structure '/%postname%/' --allow-root --path=/var/www/wordpress 2>/dev/null
        
    else
        error "WordPress installation failed or timed out"
        cat /tmp/wp_install.log
        
        # Create minimal database tables manually if needed
        log "Attempting minimal setup..."
        mysql -h"${WP_DB_HOST%%:*}" -u"${WP_DB_USER}" -p"${WP_DB_PASSWORD}" "${WP_DB_NAME}" -e "SHOW TABLES;" 2>/dev/null
    fi
else
    log "WordPress is already installed"
fi

# Final permission settings
log "Setting final permissions..."
chown -R www-data:www-data /var/www/wordpress
find /var/www/wordpress -type d -exec chmod 755 {} \;
find /var/www/wordpress -type f -exec chmod 644 {} \;

# Create PHP test file
cat > /var/www/wordpress/test.php << 'EOF'
<?php
echo "PHP is working!\n";
echo "PHP Version: " . phpversion() . "\n";
echo "Server: " . $_SERVER['SERVER_SOFTWARE'] . "\n";
phpinfo();
?>
EOF
chown www-data:www-data /var/www/wordpress/test.php

log "WordPress setup complete!"
log "========================================="
log "Site URL: https://${DOMAIN_NAME}"
log "Test PHP: https://${DOMAIN_NAME}/test.php"
log "========================================="

# Remove the trap since we're about to start PHP-FPM normally
trap - EXIT

# Start PHP-FPM (this will not return)
start_php_fpm
