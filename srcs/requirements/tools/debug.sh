#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Inception Debug Tool${NC}"
echo -e "${GREEN}========================================${NC}"

# Check containers
echo -e "\n${YELLOW}1. Container Status:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check MariaDB
echo -e "\n${YELLOW}2. MariaDB Status:${NC}"
docker exec mariadb mysqladmin -u root -ptsukuba ping 2>/dev/null && echo -e "${GREEN}MariaDB is running${NC}" || echo -e "${RED}MariaDB is not responding${NC}"

# Check WordPress database connection
echo -e "\n${YELLOW}3. WordPress Database Connection:${NC}"
docker exec wordpress php -r "
\$conn = @mysqli_connect('mariadb', 'nkannan', 'tsuchiura', 'wordpress');
if (\$conn) {
    echo 'Connection: SUCCESS\n';
    mysqli_close(\$conn);
} else {
    echo 'Connection: FAILED - ' . mysqli_connect_error() . '\n';
}
" 2>/dev/null || echo -e "${RED}WordPress container not ready${NC}"

# Check WordPress installation
echo -e "\n${YELLOW}4. WordPress Installation:${NC}"
docker exec wordpress wp core is-installed --allow-root --path=/var/www/wordpress 2>/dev/null && echo -e "${GREEN}WordPress is installed${NC}" || echo -e "${RED}WordPress is not installed${NC}"

# Check volumes
echo -e "\n${YELLOW}5. Volume Status:${NC}"
echo "MariaDB data: $(ls -la data/mariadb 2>/dev/null | wc -l) files"
echo "WordPress data: $(ls -la data/wordpress 2>/dev/null | wc -l) files"

# Check network
echo -e "\n${YELLOW}6. Network Connectivity:${NC}"
docker exec wordpress ping -c 1 mariadb >/dev/null 2>&1 && echo -e "${GREEN}Network: OK${NC}" || echo -e "${RED}Network: Failed${NC}"

echo -e "\n${GREEN}========================================${NC}"
