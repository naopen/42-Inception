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

# Function to test database connection
test_db_connection() {
    mysql -h"${WP_DB_HOST%%:*}" -P"${WP_DB_HOST##*:}" -u"${WP_DB_USER}" -p"${WP_DB_PASSWORD}" -e "SELECT 1;" 2>/dev/null
    return $?
}

# Function to test and debug database connection
debug_db_connection() {
    local host="${WP_DB_HOST%%:*}"
    local port="${WP_DB_HOST##*:}"
    
    log "Testing database connection to ${host}:${port}..."
    
    # Try connection with verbose error output
    mysql -h"${host}" -P"${port}" -u"${WP_DB_USER}" -p"${WP_DB_PASSWORD}" -e "SELECT 1;" 2>&1 | head -5
    
    if [ $? -ne 0 ]; then
        error "Failed to connect to database"
        
        # Try to get more info
        log "Checking if MariaDB host is reachable..."
        if command -v ping >/dev/null 2>&1; then
            ping -c 1 "${host}" 2>&1 | head -3
        fi
        
        if command -v nc >/dev/null 2>&1; then
            nc -zv "${host}" "${port}" 2>&1
        fi
        
        # Try connecting without password to see different error
        log "Testing connection without credentials..."
        mysql -h"${host}" -P"${port}" -u"${WP_DB_USER}" -e "SELECT 1;" 2>&1 | head -3
        
        return 1
    fi
    
    log "Database connection successful!"
    return 0
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

# Debug: Print environment variables
log "Environment Variables:"
log "  WP_DB_HOST: ${WP_DB_HOST}"
log "  WP_DB_NAME: ${WP_DB_NAME}"
log "  WP_DB_USER: ${WP_DB_USER}"
log "  DOMAIN_NAME: ${DOMAIN_NAME}"

# Wait for MariaDB to be ready
log "Waiting for MariaDB to be ready..."
max_retries=60
retry_count=0

while [ $retry_count -lt $max_retries ]; do
    if test_db_connection; then
        log "MariaDB is ready and accepting connections!"
        break
    fi
    retry_count=$((retry_count + 1))
    if [ $retry_count -eq $max_retries ]; then
        error "MariaDB did not become ready in time"
        
        # Debug information
        log "Attempting to get more information..."
        log "Trying to ping MariaDB host..."
        ping -c 1 "${WP_DB_HOST%%:*}" 2>&1 | head -3
        
        log "Trying to connect with nc..."
        nc -zv "${WP_DB_HOST%%:*}" 3306 2>&1
        
        # Start PHP-FPM anyway
        start_php_fpm
    fi
    log "Waiting for database... (${retry_count}/${max_retries})"
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
        
        # Test database connection
        if test_db_connection; then
            log "Database connection is working."
        else
            warning "Database connection failed. Recreating wp-config.php..."
            rm -f /var/www/wordpress/wp-config.php
        fi
    else
        log "WordPress installation check failed. Proceeding with setup..."
    fi
fi

log "Starting WordPress installation and configuration..."

# Download WordPress if not exists
if [ ! -f /var/www/wordpress/index.php ]; then
    log "Downloading WordPress core files..."
    wp core download \
        --allow-root \
        --path=/var/www/wordpress \
        --locale=en_US \
        --force
fi

# Create wp-config.php if it doesn't exist
if [ ! -f /var/www/wordpress/wp-config.php ]; then
    log "Creating wp-config.php..."
    
    # Test database connection before creating wp-config
    if test_db_connection; then
        log "Database connection test successful!"
    else
        error "Cannot connect to database. Please check credentials."
        error "Host: ${WP_DB_HOST%%:*}, Port: ${WP_DB_HOST##*:}"
        error "User: ${WP_DB_USER}, Database: ${WP_DB_NAME}"
    fi
    
    # Create wp-config using WP-CLI
    wp config create \
        --dbname="${WP_DB_NAME}" \
        --dbuser="${WP_DB_USER}" \
        --dbpass="${WP_DB_PASSWORD}" \
        --dbhost="${WP_DB_HOST}" \
        --dbcharset="utf8mb4" \
        --dbcollate="" \
        --locale=en_US \
        --allow-root \
        --path=/var/www/wordpress \
        --force
    
    # Add additional configuration
    cat >> /var/www/wordpress/wp-config.php << 'EOFCONFIG'

// Site URL settings
define( 'WP_HOME', 'https://' . getenv('DOMAIN_NAME') );
define( 'WP_SITEURL', 'https://' . getenv('DOMAIN_NAME') );

// Force SSL
define( 'FORCE_SSL_ADMIN', true );

// Memory limits
define( 'WP_MEMORY_LIMIT', '128M' );

// Disable file editing
define( 'DISALLOW_FILE_EDIT', true );

// Debug settings (disable in production)
define( 'WP_DEBUG', false );
define( 'WP_DEBUG_LOG', false );
define( 'WP_DEBUG_DISPLAY', false );
EOFCONFIG
    
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
    
    # Test database connection one more time
    if test_db_connection; then
        log "Database connection verified. Proceeding with installation..."
        
        wp core install \
            --url="https://${DOMAIN_NAME}" \
            --title="Inception - 42 Project" \
            --admin_user="${WP_ADMIN_USER}" \
            --admin_password="${WP_ADMIN_PASSWORD}" \
            --admin_email="${WP_ADMIN_EMAIL}" \
            --skip-email \
            --allow-root \
            --path=/var/www/wordpress
        
        if [ $? -eq 0 ]; then
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
            error "WordPress installation failed"
        fi
    else
        error "Cannot connect to database. WordPress installation skipped."
        error "Please check database configuration and restart the container."
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

// Test database connection
$connection = @mysqli_connect(
    getenv('WP_DB_HOST') ?: 'mariadb',
    getenv('WP_DB_USER'),
    getenv('WP_DB_PASSWORD'),
    getenv('WP_DB_NAME')
);

if ($connection) {
    echo "Database connection: SUCCESS\n";
    mysqli_close($connection);
} else {
    echo "Database connection: FAILED - " . mysqli_connect_error() . "\n";
}
?>
EOF
chown www-data:www-data /var/www/wordpress/test.php

log "WordPress setup complete!"
log "========================================="
log "Site URL: https://${DOMAIN_NAME}"
log "Test PHP: https://${DOMAIN_NAME}/test.php"
log "Admin: ${WP_ADMIN_USER}"
log "========================================="

# Remove the trap since we're about to start PHP-FPM normally
trap - EXIT

# Start PHP-FPM (this will not return)
start_php_fpm
