#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load environment
source srcs/.env

echo -e "${MAGENTA}========================================${NC}"
echo -e "${MAGENTA}   Database Connection Debugging${NC}"
echo -e "${MAGENTA}========================================${NC}"

# 1. Check if MariaDB container is running
echo -e "\n${CYAN}1. MariaDB Container Status:${NC}"
if docker ps | grep -q mariadb; then
    echo -e "${GREEN}✓ MariaDB container is running${NC}"
    
    # Get container details
    echo -e "\n${YELLOW}Container Details:${NC}"
    docker inspect mariadb --format='Name: {{.Name}}
State: {{.State.Status}}
Started: {{.State.StartedAt}}
IP: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
    
else
    echo -e "${RED}✗ MariaDB container is not running${NC}"
    echo -e "\n${YELLOW}Attempting to view last logs:${NC}"
    docker logs mariadb --tail 50
    exit 1
fi

# 2. Test database connectivity from host
echo -e "\n${CYAN}2. Database Connectivity Test:${NC}"

# Test from within MariaDB container
echo -e "\n${YELLOW}Testing from MariaDB container:${NC}"
docker exec mariadb sh -c "
    echo 'Testing local connection as root...'
    if mysql -u root -p'${MYSQL_ROOT_PASSWORD}' -e 'SHOW DATABASES;' 2>/dev/null; then
        echo '✓ Root user can connect locally'
        mysql -u root -p'${MYSQL_ROOT_PASSWORD}' -e 'SHOW DATABASES;' 2>/dev/null
    else
        echo '✗ Root user cannot connect locally'
    fi
    
    echo ''
    echo 'Testing wordpress database exists...'
    if mysql -u root -p'${MYSQL_ROOT_PASSWORD}' -e 'USE ${MYSQL_DATABASE}; SHOW TABLES;' 2>/dev/null; then
        echo '✓ WordPress database exists'
        mysql -u root -p'${MYSQL_ROOT_PASSWORD}' -e 'USE ${MYSQL_DATABASE}; SHOW TABLES;' 2>/dev/null | head -10
    else
        echo '✗ WordPress database does not exist or cannot be accessed'
    fi
    
    echo ''
    echo 'Checking user privileges...'
    mysql -u root -p'${MYSQL_ROOT_PASSWORD}' -e \"SELECT User, Host FROM mysql.user WHERE User='${MYSQL_USER}';\" 2>/dev/null
    mysql -u root -p'${MYSQL_ROOT_PASSWORD}' -e \"SHOW GRANTS FOR '${MYSQL_USER}'@'%';\" 2>/dev/null
"

# 3. Test connectivity from WordPress container
echo -e "\n${CYAN}3. Testing from WordPress Container:${NC}"
if docker ps | grep -q wordpress; then
    echo -e "${GREEN}✓ WordPress container is running${NC}"
    
    # Test database connection from WordPress
    echo -e "\n${YELLOW}Testing database connection from WordPress:${NC}"
    docker exec wordpress sh -c "
        echo 'Attempting to connect to database...'
        mysql -h '${WP_DB_HOST%%:*}' -u '${WP_DB_USER}' -p'${WP_DB_PASSWORD}' -e 'SELECT 1;' 2>&1
        
        if [ \$? -eq 0 ]; then
            echo '✓ WordPress can connect to MariaDB'
        else
            echo '✗ WordPress cannot connect to MariaDB'
            echo ''
            echo 'Testing DNS resolution:'
            ping -c 1 mariadb 2>&1 | head -3
            echo ''
            echo 'Testing port connectivity:'
            nc -zv mariadb 3306 2>&1
        fi
    "
    
    # Check wp-config.php
    echo -e "\n${YELLOW}WordPress Configuration:${NC}"
    docker exec wordpress sh -c "
        if [ -f /var/www/wordpress/wp-config.php ]; then
            echo 'wp-config.php exists'
            echo ''
            echo 'Database configuration in wp-config.php:'
            grep -E 'DB_NAME|DB_USER|DB_PASSWORD|DB_HOST' /var/www/wordpress/wp-config.php | grep define
        else
            echo 'wp-config.php does not exist!'
        fi
    "
else
    echo -e "${RED}✗ WordPress container is not running${NC}"
    echo -e "\n${YELLOW}Last logs:${NC}"
    docker logs wordpress --tail 30
fi

# 4. Network inspection
echo -e "\n${CYAN}4. Network Configuration:${NC}"
docker network inspect srcs_inception_network --format='Network: {{.Name}}
Driver: {{.Driver}}
Containers:
{{range .Containers}}  {{.Name}}: {{.IPv4Address}}
{{end}}'

# 5. Check if data directories exist and have correct permissions
echo -e "\n${CYAN}5. Data Directory Permissions:${NC}"
echo -e "${YELLOW}MariaDB data directory:${NC}"
if [ -d "${DATA_PATH}/mariadb" ]; then
    ls -la "${DATA_PATH}/mariadb" | head -5
    echo "Total size: $(du -sh ${DATA_PATH}/mariadb 2>/dev/null | cut -f1)"
else
    echo -e "${RED}Directory does not exist${NC}"
fi

echo -e "\n${YELLOW}WordPress data directory:${NC}"
if [ -d "${DATA_PATH}/wordpress" ]; then
    ls -la "${DATA_PATH}/wordpress" | head -5
    echo "Total size: $(du -sh ${DATA_PATH}/wordpress 2>/dev/null | cut -f1)"
else
    echo -e "${RED}Directory does not exist${NC}"
fi

# 6. Environment variables validation
echo -e "\n${CYAN}6. Environment Variables Validation:${NC}"
echo "Database Name: ${MYSQL_DATABASE}"
echo "Database User: ${MYSQL_USER}"
echo "Database Host: ${WP_DB_HOST}"
echo "WordPress DB Name: ${WP_DB_NAME}"
echo "WordPress DB User: ${WP_DB_USER}"

if [ "${MYSQL_DATABASE}" != "${WP_DB_NAME}" ]; then
    echo -e "${RED}✗ Database name mismatch!${NC}"
    echo "  MariaDB creates: ${MYSQL_DATABASE}"
    echo "  WordPress expects: ${WP_DB_NAME}"
fi

if [ "${MYSQL_USER}" != "${WP_DB_USER}" ]; then
    echo -e "${RED}✗ Database user mismatch!${NC}"
    echo "  MariaDB creates: ${MYSQL_USER}"
    echo "  WordPress expects: ${WP_DB_USER}"
fi

if [ "${MYSQL_PASSWORD}" != "${WP_DB_PASSWORD}" ]; then
    echo -e "${RED}✗ Database password mismatch!${NC}"
fi

# 7. Recommendations
echo -e "\n${MAGENTA}========================================${NC}"
echo -e "${MAGENTA}   Recommendations${NC}"
echo -e "${MAGENTA}========================================${NC}"

echo -e "\n${YELLOW}If database connection is failing:${NC}"
echo "1. Clean everything and rebuild:"
echo -e "   ${GREEN}make fclean && make${NC}"
echo ""
echo "2. If the problem persists, manually check MariaDB:"
echo -e "   ${GREEN}docker exec -it mariadb bash${NC}"
echo -e "   ${GREEN}mysql -u root -p${MYSQL_ROOT_PASSWORD}${NC}"
echo ""
echo "3. Check if WordPress user exists and has correct permissions:"
echo -e "   ${GREEN}SELECT User, Host FROM mysql.user;${NC}"
echo -e "   ${GREEN}SHOW GRANTS FOR '${MYSQL_USER}'@'%';${NC}"
echo ""
echo "4. If needed, manually create user and grant permissions:"
echo -e "   ${GREEN}CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';${NC}"
echo -e "   ${GREEN}GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';${NC}"
echo -e "   ${GREEN}FLUSH PRIVILEGES;${NC}"

echo -e "\n${MAGENTA}========================================${NC}"
