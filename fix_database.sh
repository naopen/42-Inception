#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Manual Database Fix${NC}"
echo -e "${GREEN}========================================${NC}"

# Load environment
source srcs/.env

echo -e "\n${YELLOW}Creating database and user manually...${NC}"

# Create SQL commands
cat > /tmp/fix_db.sql << EOF
-- Create database if not exists
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user for all hosts
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Create user for localhost
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';

-- Create user for wordpress container
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'wordpress' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'wordpress';

-- Create user for specific network
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'172.%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'172.%';

-- Flush privileges
FLUSH PRIVILEGES;

-- Show results
SELECT User, Host FROM mysql.user WHERE User='${MYSQL_USER}';
SHOW DATABASES;
EOF

echo -e "${YELLOW}Executing SQL commands...${NC}"
docker exec -i mariadb mysql -uroot -p${MYSQL_ROOT_PASSWORD} < /tmp/fix_db.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database and user created successfully!${NC}"
    
    # Test connection from WordPress container
    echo -e "\n${YELLOW}Testing connection from WordPress container...${NC}"
    docker exec wordpress mysql -h mariadb -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "USE ${MYSQL_DATABASE}; SELECT 'Connection successful!' as Result;" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ WordPress can connect to MariaDB!${NC}"
        
        # Restart WordPress container to retry installation
        echo -e "\n${YELLOW}Restarting WordPress container...${NC}"
        docker restart wordpress
        
        echo -e "${GREEN}✓ WordPress container restarted${NC}"
        echo -e "\n${GREEN}Waiting for WordPress to install...${NC}"
        sleep 10
        
        # Check WordPress logs
        echo -e "\n${YELLOW}Recent WordPress logs:${NC}"
        docker logs wordpress --tail 20
    else
        echo -e "${RED}✗ WordPress still cannot connect to MariaDB${NC}"
    fi
else
    echo -e "${RED}✗ Failed to create database and user${NC}"
fi

# Clean up
rm -f /tmp/fix_db.sql

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   Done!${NC}"
echo -e "${GREEN}========================================${NC}"
