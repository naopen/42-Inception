#!/bin/bash

# Complete cleanup and restart script for Inception project
# Use this when you encounter database connection issues

echo "========================================="
echo "   Inception Complete Cleanup & Restart"
echo "========================================="

# Stop all containers
echo "Stopping all containers..."
docker-compose -f srcs/docker-compose.yml down -v 2>/dev/null

# Remove containers forcefully if needed
docker kill $(docker ps -aq) 2>/dev/null
docker rm $(docker ps -aq) 2>/dev/null

# Remove images
echo "Removing Docker images..."
docker rmi srcs-nginx srcs-wordpress srcs-mariadb 2>/dev/null

# Clean up volumes
echo "Cleaning up volumes..."
docker volume rm srcs_mariadb_data srcs_wordpress_data 2>/dev/null

# Clean up data directories
echo "Cleaning up data directories..."
rm -rf data/mariadb/* data/wordpress/*

# Ensure directories exist
mkdir -p data/mariadb data/wordpress

echo "Cleanup complete!"
echo ""
echo "To restart the project, run: make"
echo "========================================="
