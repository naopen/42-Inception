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
echo -e "${MAGENTA}   Inception Troubleshooting${NC}"
echo -e "${MAGENTA}========================================${NC}"

# Check Docker status
echo -e "\n${CYAN}1. Docker Status:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check container logs
echo -e "\n${CYAN}2. Container Health:${NC}"

# Check NGINX
echo -e "${YELLOW}NGINX:${NC}"
if docker ps | grep -q nginx; then
    if docker exec nginx nginx -t 2>/dev/null; then
        echo -e "${GREEN}✓ NGINX configuration is valid${NC}"
    else
        echo -e "${RED}✗ NGINX configuration error${NC}"
        echo "Last logs:"
        docker logs nginx --tail 10
    fi
else
    echo -e "${RED}✗ NGINX container not running${NC}"
    echo "Last logs:"
    docker logs nginx --tail 10
fi

# Check WordPress
echo -e "\n${YELLOW}WordPress:${NC}"
if docker ps | grep -q wordpress; then
    echo -e "${GREEN}✓ WordPress container is running${NC}"
    # Check if WordPress is installed
    if docker exec wordpress wp core is-installed --allow-root --path=/var/www/wordpress 2>/dev/null; then
        echo -e "${GREEN}✓ WordPress is installed${NC}"
    else
        echo -e "${YELLOW}⚠ WordPress installation in progress or failed${NC}"
    fi
else
    echo -e "${RED}✗ WordPress container not running${NC}"
    echo "Last logs:"
    docker logs wordpress --tail 10
fi

# Check MariaDB
echo -e "\n${YELLOW}MariaDB:${NC}"
if docker ps | grep -q mariadb; then
    echo -e "${GREEN}✓ MariaDB container is running${NC}"
    # Test database connection
    if docker exec mariadb mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD} 2>/dev/null; then
        echo -e "${GREEN}✓ Database is responsive${NC}"
    else
        echo -e "${RED}✗ Database not responding${NC}"
    fi
else
    echo -e "${RED}✗ MariaDB container not running${NC}"
    echo "Last logs:"
    docker logs mariadb --tail 10
fi

# Check network
echo -e "\n${CYAN}3. Network Configuration:${NC}"
docker network ls | grep inception
docker network inspect srcs_inception_network --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{println}}{{end}}' 2>/dev/null

# Check volumes
echo -e "\n${CYAN}4. Volume Status:${NC}"
echo "WordPress volume:"
if [ -d "${DATA_PATH}/wordpress" ]; then
    echo -e "${GREEN}✓ WordPress data directory exists${NC}"
    ls -la ${DATA_PATH}/wordpress | head -5
else
    echo -e "${RED}✗ WordPress data directory not found${NC}"
fi

echo -e "\nMariaDB volume:"
if [ -d "${DATA_PATH}/mariadb" ]; then
    echo -e "${GREEN}✓ MariaDB data directory exists${NC}"
    ls -la ${DATA_PATH}/mariadb | head -5
else
    echo -e "${RED}✗ MariaDB data directory not found${NC}"
fi

# Check hosts file
echo -e "\n${CYAN}5. Hosts File Configuration:${NC}"
if grep -q "${DOMAIN_NAME}" /etc/hosts; then
    echo -e "${GREEN}✓ ${DOMAIN_NAME} is in /etc/hosts${NC}"
    grep "${DOMAIN_NAME}" /etc/hosts
else
    echo -e "${RED}✗ ${DOMAIN_NAME} not found in /etc/hosts${NC}"
    echo -e "${YELLOW}Add this line to /etc/hosts:${NC}"
    echo -e "${GREEN}127.0.0.1    ${DOMAIN_NAME}${NC}"
fi

# Check port 443
echo -e "\n${CYAN}6. Port 443 Status:${NC}"
if lsof -i :443 2>/dev/null | grep -q LISTEN; then
    echo -e "${GREEN}✓ Port 443 is listening${NC}"
    lsof -i :443 | grep LISTEN
else
    echo -e "${RED}✗ Port 443 is not listening${NC}"
    echo -e "${YELLOW}Checking Docker port mapping:${NC}"
    docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 443
fi

# Environment variables check
echo -e "\n${CYAN}7. Environment Variables:${NC}"
echo "DOMAIN_NAME: ${DOMAIN_NAME}"
echo "DATA_PATH: ${DATA_PATH}"
echo "WordPress Admin: ${WP_ADMIN_USER}"

# Provide solutions
echo -e "\n${MAGENTA}========================================${NC}"
echo -e "${MAGENTA}   Recommended Actions${NC}"
echo -e "${MAGENTA}========================================${NC}"

if ! grep -q "${DOMAIN_NAME}" /etc/hosts; then
    echo -e "\n${YELLOW}1. Add domain to hosts file:${NC}"
    echo -e "   ${GREEN}sudo sh -c 'echo \"127.0.0.1    ${DOMAIN_NAME}\" >> /etc/hosts'${NC}"
fi

if ! docker ps | grep -q nginx || ! docker ps | grep -q wordpress || ! docker ps | grep -q mariadb; then
    echo -e "\n${YELLOW}2. Restart containers:${NC}"
    echo -e "   ${GREEN}make restart${NC}"
fi

echo -e "\n${YELLOW}3. Access your site:${NC}"
echo -e "   ${GREEN}https://${DOMAIN_NAME}${NC}"
echo -e "   ${GREEN}https://localhost${NC} (alternative)"

echo -e "\n${YELLOW}4. If still having issues:${NC}"
echo -e "   ${GREEN}make fclean && make${NC}"

echo -e "\n${MAGENTA}========================================${NC}"
