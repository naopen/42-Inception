#!/bin/bash

# Start MySQL service for initial setup if data directory is empty
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing database..."
    
    # Initialize MySQL data directory
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    # Start MySQL in background for initial setup
    mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;

-- Delete default users
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create database
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Create user and grant privileges
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
    
    echo "Database initialized successfully!"
else
    echo "Database already initialized, skipping..."
fi

# Execute the CMD (mysqld)
exec "$@"
