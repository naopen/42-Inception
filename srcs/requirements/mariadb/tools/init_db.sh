#!/bin/bash

# Exit on error
set -e

echo "[MariaDB] Starting MariaDB initialization script..."

# Ensure mysql user owns the data directory
chown -R mysql:mysql /var/lib/mysql

# Check if our specific database exists (not just mysql system db)
DB_EXISTS=$(mysql -u root -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';" 2>/dev/null | grep "${MYSQL_DATABASE}" || echo "")

if [ -z "$DB_EXISTS" ]; then
    echo "[MariaDB] Database '${MYSQL_DATABASE}' not found. Initializing..."
    
    # If mysql directory doesn't exist, initialize it
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "[MariaDB] Initializing MariaDB data directory..."
        mysql_install_db --user=mysql --datadir=/var/lib/mysql --auth-root-authentication-method=normal
    fi
    
    # Start temporary MariaDB server
    echo "[MariaDB] Starting temporary MariaDB server..."
    mysqld_safe --user=mysql --skip-networking &
    MYSQL_PID=$!
    
    # Wait for MariaDB to be ready
    echo "[MariaDB] Waiting for MariaDB to start..."
    for i in {1..30}; do
        if mysqladmin ping >/dev/null 2>&1; then
            echo "[MariaDB] MariaDB is ready"
            break
        fi
        sleep 1
    done
    
    # Configure database
    echo "[MariaDB] Configuring database..."
    mysql << EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Remove existing users if any
DROP USER IF EXISTS '${MYSQL_USER}'@'%';
DROP USER IF EXISTS '${MYSQL_USER}'@'localhost';

-- Create user and grant privileges
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Allow root from any host
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;

-- Flush privileges
FLUSH PRIVILEGES;
EOF
    
    # Shutdown temporary server
    echo "[MariaDB] Shutting down temporary server..."
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait $MYSQL_PID
    
    echo "[MariaDB] Database initialization complete!"
else
    echo "[MariaDB] Database '${MYSQL_DATABASE}' already exists."
fi

# Ensure correct permissions
chown -R mysql:mysql /var/lib/mysql
chmod 755 /var/lib/mysql

# Create run directory for socket
mkdir -p /var/run/mysqld
chown mysql:mysql /var/run/mysqld
chmod 755 /var/run/mysqld

echo "[MariaDB] Starting MariaDB server..."
# Start MariaDB server
exec mysqld --user=mysql --bind-address=0.0.0.0
