#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load environment
source srcs/.env

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   Inception Host Configuration${NC}"
echo -e "${CYAN}========================================${NC}"

echo -e "\n${YELLOW}To access your WordPress site, add this line to /etc/hosts:${NC}"
echo -e "${GREEN}127.0.0.1    ${DOMAIN_NAME}${NC}"

echo -e "\n${YELLOW}You can do this with:${NC}"
echo -e "${GREEN}sudo sh -c 'echo \"127.0.0.1    ${DOMAIN_NAME}\" >> /etc/hosts'${NC}"

echo -e "\n${YELLOW}Or manually edit /etc/hosts:${NC}"
echo -e "${GREEN}sudo nano /etc/hosts${NC}"

echo -e "\n${YELLOW}To verify it's working:${NC}"
echo -e "${GREEN}ping -c 1 ${DOMAIN_NAME}${NC}"

echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}After adding the hosts entry, access:${NC}"
echo -e "${GREEN}https://${DOMAIN_NAME}${NC}"
echo -e "${GREEN}https://${DOMAIN_NAME}/wp-admin${NC}"
echo -e "${CYAN}========================================${NC}"
