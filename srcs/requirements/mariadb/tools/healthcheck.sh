#!/bin/bash

# MariaDB Health Check Script for Virtual Box environments
# This script helps diagnose MariaDB connection issues

echo "=== MariaDB Health Check ==="

# Check if mysqld process is running
echo "Checking MariaDB process..."
if pgrep mysqld > /dev/null; then
    echo "✓ MariaDB process is running"
    echo "  PIDs: $(pgrep mysqld | tr '\n' ' ')"
else
    echo "✗ MariaDB process is not running"
fi

# Check socket file
echo "Checking socket file..."
if [ -S /tmp/mysql.sock ]; then
    echo "✓ Socket file exists at /tmp/mysql.sock"
    ls -la /tmp/mysql.sock
else
    echo "✗ Socket file does not exist at /tmp/mysql.sock"
fi

# Check if MariaDB is accepting connections
echo "Checking MariaDB connectivity..."
if mysqladmin ping -S /tmp/mysql.sock > /dev/null 2>&1; then
    echo "✓ MariaDB is accepting connections"
else
    echo "✗ MariaDB is not accepting connections"
fi

# Check data directory
echo "Checking data directory..."
if [ -d /var/lib/mysql/mysql ]; then
    echo "✓ Data directory is initialized"
    echo "  Size: $(du -sh /var/lib/mysql | cut -f1)"
else
    echo "✗ Data directory is not properly initialized"
fi

# Check configuration
echo "Checking configuration..."
if [ -f /etc/mysql/mariadb.conf.d/50-server.cnf ]; then
    echo "✓ Configuration file exists"
    echo "  Socket setting: $(grep 'socket =' /etc/mysql/mariadb.conf.d/50-server.cnf | head -1)"
else
    echo "✗ Configuration file missing"
fi

# Check port binding
echo "Checking port binding..."
if netstat -ln | grep :3306 > /dev/null 2>&1; then
    echo "✓ Port 3306 is bound"
    netstat -ln | grep :3306
else
    echo "✗ Port 3306 is not bound"
fi

# Check logs
echo "Checking logs..."
if [ -f /var/log/mysql/error.log ]; then
    echo "Error log (last 10 lines):"
    tail -10 /var/log/mysql/error.log
else
    echo "No error log found"
fi

echo "=== Health Check Complete ==="
