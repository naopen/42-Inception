#!/bin/bash

# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    evaluation_check.sh                                :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: nkannan <nkannan@student.42tokyo.jp>       +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/08/10 10:00:00 by nkannan         #+#    #+#              #
#    Updated: 2025/08/10 10:00:00 by nkannan          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test results
PASSED=0
FAILED=0

# Load environment variables
source srcs/.env

# Test function
test_requirement() {
    local description="$1"
    local command="$2"
    local expected="$3"
    
    echo -n "Testing: $description... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
        echo "  Command: $command"
        echo "  Expected: $expected"
        ((FAILED++))
    fi
}

echo -e "${MAGENTA}========================================"
echo "   Inception Evaluation Checker"
echo -e "========================================${NC}"

echo -e "\n${CYAN}1. PRELIMINARY CHECKS${NC}"
echo "----------------------------------------"

# Check for credentials in repository
test_requirement "No credentials in Git" \
    "! grep -r 'password\\|PASSWORD' srcs/requirements --include='*.sh' --include='*.conf' --include='Dockerfile' | grep -v '\$'" \
    "No hardcoded passwords"

test_requirement ".env file exists" \
    "[ -f srcs/.env ]" \
    ".env file present"

echo -e "\n${CYAN}2. GENERAL INSTRUCTIONS${NC}"
echo "----------------------------------------"

test_requirement "srcs folder exists" \
    "[ -d srcs ]" \
    "srcs folder at root"

test_requirement "Makefile exists" \
    "[ -f Makefile ]" \
    "Makefile at root"

test_requirement "docker-compose.yml in srcs" \
    "[ -f srcs/docker-compose.yml ]" \
    "docker-compose.yml in srcs"

test_requirement "No 'network: host'" \
    "! grep -q 'network: host' srcs/docker-compose.yml" \
    "No 'network: host' in docker-compose.yml"

test_requirement "No 'links:'" \
    "! grep -q 'links:' srcs/docker-compose.yml" \
    "No 'links:' in docker-compose.yml"

test_requirement "Networks defined" \
    "grep -q 'networks:' srcs/docker-compose.yml" \
    "Networks in docker-compose.yml"

test_requirement "No '--link' in scripts" \
    "! grep -r -- '--link' srcs/" \
    "No '--link' usage"

test_requirement "No 'tail -f' in ENTRYPOINT" \
    "! grep -r 'tail -f' srcs/requirements --include='Dockerfile'" \
    "No 'tail -f' in Dockerfiles"

test_requirement "No infinite loops" \
    "! grep -r 'sleep infinity\\|tail -f /dev/null\\|while true' srcs/requirements" \
    "No infinite loops"

echo -e "\n${CYAN}3. DOCKER SETUP${NC}"
echo "----------------------------------------"

test_requirement "Three Dockerfiles exist" \
    "[ -f srcs/requirements/nginx/Dockerfile ] && [ -f srcs/requirements/wordpress/Dockerfile ] && [ -f srcs/requirements/mariadb/Dockerfile ]" \
    "One Dockerfile per service"

test_requirement "Dockerfiles not empty" \
    "[ -s srcs/requirements/nginx/Dockerfile ] && [ -s srcs/requirements/wordpress/Dockerfile ] && [ -s srcs/requirements/mariadb/Dockerfile ]" \
    "Dockerfiles have content"

test_requirement "Using Debian or Alpine" \
    "grep -E '^FROM (debian|alpine)' srcs/requirements/*/Dockerfile" \
    "Base images from Debian or Alpine"

test_requirement "No latest tags" \
    "! grep -r ':latest' srcs/" \
    "No :latest tags used"

echo -e "\n${CYAN}4. NGINX CONFIGURATION${NC}"
echo "----------------------------------------"

test_requirement "NGINX Dockerfile exists" \
    "[ -f srcs/requirements/nginx/Dockerfile ]" \
    "NGINX Dockerfile present"

test_requirement "SSL certificate script" \
    "[ -f srcs/requirements/nginx/tools/generate_ssl.sh ]" \
    "SSL generation script exists"

test_requirement "NGINX config for 443 only" \
    "grep -q 'listen 443' srcs/requirements/nginx/conf/default.conf && ! grep -q 'listen 80[^0-9]' srcs/requirements/nginx/conf/default.conf || grep -q 'return 444' srcs/requirements/nginx/conf/default.conf" \
    "NGINX listens on 443 only"

test_requirement "TLS configured" \
    "grep -q 'ssl_protocols.*TLSv1.[23]' srcs/requirements/nginx/conf/default.conf" \
    "TLSv1.2 or TLSv1.3 configured"

echo -e "\n${CYAN}5. WORDPRESS CONFIGURATION${NC}"
echo "----------------------------------------"

test_requirement "WordPress Dockerfile exists" \
    "[ -f srcs/requirements/wordpress/Dockerfile ]" \
    "WordPress Dockerfile present"

test_requirement "No NGINX in WordPress" \
    "! grep -i nginx srcs/requirements/wordpress/Dockerfile" \
    "WordPress container without NGINX"

test_requirement "PHP-FPM configured" \
    "grep -q 'php.*fpm' srcs/requirements/wordpress/Dockerfile" \
    "PHP-FPM in WordPress"

test_requirement "WP-CLI installed" \
    "grep -q 'wp-cli' srcs/requirements/wordpress/Dockerfile" \
    "WP-CLI installation"

test_requirement "Setup script exists" \
    "[ -f srcs/requirements/wordpress/tools/wp_setup.sh ]" \
    "WordPress setup script"

echo -e "\n${CYAN}6. MARIADB CONFIGURATION${NC}"
echo "----------------------------------------"

test_requirement "MariaDB Dockerfile exists" \
    "[ -f srcs/requirements/mariadb/Dockerfile ]" \
    "MariaDB Dockerfile present"

test_requirement "No NGINX in MariaDB" \
    "! grep -i nginx srcs/requirements/mariadb/Dockerfile" \
    "MariaDB container without NGINX"

test_requirement "Init script exists" \
    "[ -f srcs/requirements/mariadb/tools/init_db.sh ]" \
    "Database initialization script"

echo -e "\n${CYAN}7. DOCKER COMPOSE${NC}"
echo "----------------------------------------"

test_requirement "Three services defined" \
    "grep -c '^  [a-z]*:' srcs/docker-compose.yml | grep -q '3'" \
    "Three services in docker-compose"

test_requirement "Volumes defined" \
    "grep -q 'volumes:' srcs/docker-compose.yml" \
    "Volumes configuration"

test_requirement "Networks defined" \
    "grep -q 'networks:' srcs/docker-compose.yml" \
    "Networks configuration"

test_requirement "Restart policy" \
    "grep -c 'restart: always' srcs/docker-compose.yml | grep -q '3'" \
    "All services have restart: always"

echo -e "\n${CYAN}8. ENVIRONMENT VARIABLES${NC}"
echo "----------------------------------------"

test_requirement "Domain name set" \
    "grep -q 'DOMAIN_NAME=' srcs/.env" \
    "DOMAIN_NAME in .env"

test_requirement "Database variables" \
    "grep -q 'MYSQL_DATABASE=' srcs/.env && grep -q 'MYSQL_USER=' srcs/.env" \
    "Database variables in .env"

test_requirement "WordPress variables" \
    "grep -q 'WP_ADMIN_USER=' srcs/.env && grep -q 'WP_USER=' srcs/.env" \
    "WordPress users in .env"

test_requirement "No 'admin' in admin username" \
    "! grep 'WP_ADMIN_USER=' srcs/.env | grep -i 'admin[^_]'" \
    "Admin username doesn't contain 'admin'"

echo -e "\n${CYAN}9. DATA PERSISTENCE${NC}"
echo "----------------------------------------"

test_requirement "Volume bind mounts" \
    "grep -q 'device:.*DATA_PATH' srcs/docker-compose.yml" \
    "Volumes use bind mounts to DATA_PATH"

echo -e "\n${MAGENTA}========================================"
echo "   EVALUATION RESULTS"
echo -e "========================================${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All evaluation requirements passed!${NC}"
    echo -e "${GREEN}Your project is ready for evaluation.${NC}"
else
    echo -e "\n${RED}⚠️  Some requirements failed.${NC}"
    echo -e "${YELLOW}Please fix the issues before evaluation.${NC}"
fi

echo -e "\n${CYAN}MANUAL CHECKS REQUIRED:${NC}"
echo "1. Verify WordPress is accessible at https://${DOMAIN_NAME}"
echo "2. Check that installation page doesn't appear"
echo "3. Verify two users exist (admin and regular)"
echo "4. Test adding a comment as regular user"
echo "5. Edit a page as admin user"
echo "6. Restart VM and verify persistence"

exit $FAILED
