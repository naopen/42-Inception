#!/bin/bash

# Error handling - do not exit on error for initialization
set +e

# Simple initialization for MariaDB
echo "[MariaDB] Starting initialization..."

# Check if database is already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[MariaDB] First run - initializing database..."
    
    # Initialize database
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    # Start MariaDB in background
    mysqld --user=mysql &
    pid="$!"
    
    # Wait for MariaDB to be ready
    echo "[MariaDB] Waiting for MariaDB to start..."
    sleep 5
    
    # Set up database and user using environment variables
    mysql << EOF
-- Set root password (if provided)
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create database
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Create user and grant privileges
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
    
    # Stop temporary instance
    kill "$pid"
    wait "$pid" 2>/dev/null
    
    echo "[MariaDB] Initialization complete!"
else
    echo "[MariaDB] Database already initialized."
fi

# Set permissions
chown -R mysql:mysql /var/lib/mysql

# Start MariaDB normally
echo "[MariaDB] Starting MariaDB server..."
exec mysqld --user=mysql --bind-address=0.0.0.0
