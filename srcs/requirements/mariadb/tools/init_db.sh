#!/bin/bash

# Error handling
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[MariaDB]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check required environment variables
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    error "MYSQL_ROOT_PASSWORD is not set"
    exit 1
fi

if [ -z "$MYSQL_DATABASE" ]; then
    error "MYSQL_DATABASE is not set"
    exit 1
fi

if [ -z "$MYSQL_USER" ]; then
    error "MYSQL_USER is not set"
    exit 1
fi

if [ -z "$MYSQL_PASSWORD" ]; then
    error "MYSQL_PASSWORD is not set"
    exit 1
fi

# Initialize database if not already done
if [ ! -d "/var/lib/mysql/mysql" ]; then
    log "First run detected. Initializing MariaDB database..."
    
    # Initialize MySQL data directory
    log "Running mysql_install_db..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --auth-root-authentication-method=normal
    
    if [ $? -ne 0 ]; then
        error "Failed to initialize MySQL data directory"
        exit 1
    fi
    
    log "Starting temporary MariaDB instance for setup..."
    
    # Create initialization SQL script
    cat > /tmp/init.sql << EOF
-- Security improvements
USE mysql;
FLUSH PRIVILEGES;

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Remove remote root access
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database and access to it
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create application database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create application user with specific privileges
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Create additional security restrictions
REVOKE FILE ON *.* FROM '${MYSQL_USER}'@'%';
REVOKE PROCESS ON *.* FROM '${MYSQL_USER}'@'%';
REVOKE SUPER ON *.* FROM '${MYSQL_USER}'@'%';

-- Ensure changes take effect
FLUSH PRIVILEGES;

-- Show created users for verification
SELECT User, Host FROM mysql.user;

-- Show databases for verification
SHOW DATABASES;
EOF
    
    # Execute initialization script
    mysqld --user=mysql --bootstrap < /tmp/init.sql
    
    if [ $? -eq 0 ]; then
        log "Database initialization completed successfully!"
        rm -f /tmp/init.sql
    else
        error "Database initialization failed!"
        rm -f /tmp/init.sql
        exit 1
    fi
    
    # Set proper permissions
    chown -R mysql:mysql /var/lib/mysql
    chmod 750 /var/lib/mysql
    
    log "========================================="
    log "MariaDB Setup Complete!"
    log "========================================="
    log "Database: ${MYSQL_DATABASE}"
    log "User: ${MYSQL_USER}"
    log "Root access is restricted to localhost only"
    log "========================================="
    
else
    log "Database already initialized. Starting MariaDB..."
    
    # Ensure proper permissions on existing database
    chown -R mysql:mysql /var/lib/mysql
    chmod 750 /var/lib/mysql
fi

# Start MariaDB server
log "Starting MariaDB server..."
exec "$@"
