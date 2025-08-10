#!/bin/bash

echo "Checking database status..."
docker exec mariadb mysql << EOF
SHOW DATABASES;
SELECT User, Host FROM mysql.user;
EOF

echo -e "\nCreating WordPress database and user..."
docker exec mariadb mysql << EOF
CREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'nkannan'@'%' IDENTIFIED BY 'tsuchiura';
GRANT ALL PRIVILEGES ON wordpress.* TO 'nkannan'@'%';
FLUSH PRIVILEGES;
SHOW DATABASES;
SELECT User, Host FROM mysql.user WHERE User='nkannan';
EOF

echo -e "\nTesting connection with WordPress credentials..."
docker exec mariadb mysql -unkannan -ptsuchiura wordpress -e "SELECT 'Connection successful!' as Result;"

echo -e "\nRestarting WordPress container..."
docker restart wordpress

echo -e "\nWaiting for WordPress to initialize..."
for i in {1..10}; do
    echo -n "."
    sleep 1
done
echo ""

echo -e "\nChecking WordPress logs..."
docker logs wordpress --tail 20
