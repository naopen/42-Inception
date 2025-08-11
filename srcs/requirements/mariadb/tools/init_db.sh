#!/bin/bash

# Error handling - do not exit on error for initialization
set +e

# Simple initialization for MariaDB
echo "[MariaDB] Starting initialization..."

# Debug information
echo "[MariaDB] Checking /var/lib/mysql directory..."
ls -la /var/lib/mysql/

# Check if database is already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[MariaDB] First run - initializing database..."
    
    # Initialize database
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    # Start MariaDB in background with skip-networking to prevent external connections during setup
    mysqld --user=mysql --skip-networking &
    pid="$!"
    
    # Wait for MariaDB to be ready
    echo "[MariaDB] Waiting for MariaDB to start..."
    for i in {1..30}; do
        if mysql -u root -e "SELECT 1" > /dev/null 2>&1; then
            echo "[MariaDB] MariaDB is ready for initialization"
            break
        fi
        sleep 1
    done
    
    # Set up database and user using environment variables
    echo "[MariaDB] Creating database '${MYSQL_DATABASE}' and user '${MYSQL_USER}'..."
    mysql -u root << EOF
-- Set root password
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Remove any existing user with same name
DROP USER IF EXISTS '${MYSQL_USER}'@'%';
DROP USER IF EXISTS '${MYSQL_USER}'@'localhost';

-- Create user and grant privileges
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Grant all privileges on the database
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';

-- Ensure the user can connect from any host
GRANT USAGE ON *.* TO '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

FLUSH PRIVILEGES;
EOF
    
    if [ $? -eq 0 ]; then
        echo "[MariaDB] Database and user created successfully"
    else
        echo "[MariaDB] Warning: There was an issue creating database or user"
    fi
    
    # Stop temporary instance
    echo "[MariaDB] Stopping temporary MariaDB instance..."
    kill "$pid"
    wait "$pid" 2>/dev/null
    
    echo "[MariaDB] Initialization complete!"
else
    echo "[MariaDB] Database already initialized."
    
    # Ensure user permissions are correct even on restart
    echo "[MariaDB] Verifying user permissions..."
    
    # Start MariaDB in background temporarily to fix permissions
    mysqld --user=mysql --skip-networking &
    pid="$!"
    
    # Wait for MariaDB to be ready
    for i in {1..30}; do
        if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # Re-grant permissions to ensure connectivity
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" << EOF 2>/dev/null || true
-- Ensure user exists and has proper permissions
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
    
    # Stop temporary instance
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
fi

# Set permissions
chown -R mysql:mysql /var/lib/mysql

# Start MariaDB normally
echo "[MariaDB] Starting MariaDB server..."
exec mysqld --user=mysql --bind-address=0.0.0.0
