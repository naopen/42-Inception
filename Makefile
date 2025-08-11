# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: nkannan <nkannan@student.42tokyo.jp>       +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/08/09 20:00:00 by nkannan         #+#    #+#              #
#    Updated: 2025/08/10 10:00:00 by nkannan          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME = inception

# Paths
SRCS_PATH = ./srcs
DOCKER_COMPOSE = docker compose
DOCKER_COMPOSE_FILE = $(SRCS_PATH)/docker-compose.yml

# Load environment variables from .env file
include $(SRCS_PATH)/.env
export

# Colors for output
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[0;33m
BLUE = \033[0;34m
MAGENTA = \033[0;35m
CYAN = \033[0;36m
NC = \033[0m

# Default target
all: up

# Build and start all services
up: check_env create_dirs
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)   Starting Inception Project$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(CYAN)Creating data directories...$(NC)"
	@echo "$(CYAN)Building Docker images...$(NC)"
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) build
	@echo "$(CYAN)Starting containers...$(NC)"
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) up -d
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)   Inception is running!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(YELLOW)Access WordPress at: https://$(DOMAIN_NAME)$(NC)"
	@echo "$(YELLOW)Admin panel: https://$(DOMAIN_NAME)/wp-admin$(NC)"
	@echo "$(GREEN)========================================$(NC)"

# Stop all containers
down:
	@echo "$(RED)Stopping all containers...$(NC)"
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) down

# Stop containers without removing them
stop:
	@echo "$(YELLOW)Stopping containers...$(NC)"
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) stop

# Start stopped containers
start:
	@echo "$(GREEN)Starting containers...$(NC)"
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) start

# Restart all services
restart: down up

# Build without starting
build:
	@echo "$(CYAN)Building Docker images...$(NC)"
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) build

# Show logs for all services
logs:
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) logs -f

# Show logs for specific service
logs-%:
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) logs -f $*

# Show container status
ps:
	@echo "$(BLUE)Container Status:$(NC)"
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) ps

# Clean up containers and images
clean: down
	@echo "$(RED)Removing containers and images...$(NC)"
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) down --rmi all --volumes --remove-orphans
	@docker network prune -f

# Complete cleanup including data volumes
fclean: clean
	@echo "$(RED)========================================$(NC)"
	@echo "$(RED)   Complete Cleanup$(NC)"
	@echo "$(RED)========================================$(NC)"
	@echo "$(RED)Removing all Docker data...$(NC)"
	@docker stop $$(docker ps -qa) 2>/dev/null || true
	@docker rm $$(docker ps -qa) 2>/dev/null || true
	@docker rmi -f $$(docker images -qa) 2>/dev/null || true
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@docker network rm $$(docker network ls -q) 2>/dev/null || true
	@echo "$(RED)Removing data directories...$(NC)"
	@if [ -d "$(DATA_PATH)" ]; then \
		echo "$(YELLOW)Removing $(DATA_PATH)...$(NC)"; \
		sudo rm -rf $(DATA_PATH); \
	fi
	@echo "$(GREEN)Cleanup complete!$(NC)"

# Rebuild everything from scratch
re: fclean all

# Create necessary directories
create_dirs:
	@echo "$(CYAN)Creating data directories...$(NC)"
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@echo "$(GREEN)Data directories ready at: $(DATA_PATH)$(NC)"

# Check environment configuration
check_env:
	@if [ ! -f $(SRCS_PATH)/.env ]; then \
		echo "$(RED)Error: .env file not found!$(NC)"; \
		echo "$(YELLOW)Please create $(SRCS_PATH)/.env with your configuration$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Environment configuration found$(NC)"

# Display environment information
info:
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(BLUE)   Inception Configuration$(NC)"
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(CYAN)Domain:$(NC) $(DOMAIN_NAME)"
	@echo "$(CYAN)Data Path:$(NC) $(DATA_PATH)"
	@echo "$(CYAN)WordPress Admin:$(NC) $(WP_ADMIN_USER)"
	@echo "$(CYAN)Database:$(NC) $(MYSQL_DATABASE)"
	@echo "$(BLUE)========================================$(NC)"

# Shell access to containers
shell-nginx:
	@docker exec -it nginx /bin/bash

shell-wordpress:
	@docker exec -it wordpress /bin/bash

shell-mariadb:
	@docker exec -it mariadb /bin/bash

# Database access
db:
	@docker exec -it mariadb mysql -u root -p$(MYSQL_ROOT_PASSWORD)

# WordPress CLI access
wp:
	@docker exec -it wordpress wp --allow-root --path=/var/www/wordpress $(filter-out $@,$(MAKECMDGOALS))

# Check evaluation requirements
check:
	@echo "$(MAGENTA)========================================$(NC)"
	@echo "$(MAGENTA)   Checking Evaluation Requirements$(NC)"
	@echo "$(MAGENTA)========================================$(NC)"
	@echo "$(CYAN)Checking Docker networks...$(NC)"
	@docker network ls | grep inception || echo "$(RED)Network not found!$(NC)"
	@echo "$(CYAN)Checking volumes...$(NC)"
	@docker volume ls | grep wordpress || echo "$(RED)WordPress volume not found!$(NC)"
	@docker volume ls | grep mariadb || echo "$(RED)MariaDB volume not found!$(NC)"
	@echo "$(CYAN)Checking containers...$(NC)"
	@docker ps | grep nginx || echo "$(RED)NGINX container not running!$(NC)"
	@docker ps | grep wordpress || echo "$(RED)WordPress container not running!$(NC)"
	@docker ps | grep mariadb || echo "$(RED)MariaDB container not running!$(NC)"
	@echo "$(CYAN)Checking port 443...$(NC)"
	@netstat -tuln | grep 443 || echo "$(YELLOW)Port 443 not listening (may need sudo)$(NC)"
	@echo "$(CYAN)Checking forbidden elements...$(NC)"
	@grep -r "network: host" $(SRCS_PATH) 2>/dev/null && echo "$(RED)Found 'network: host'!$(NC)" || echo "$(GREEN)No 'network: host' found$(NC)"
	@grep -r "links:" $(SRCS_PATH) 2>/dev/null && echo "$(RED)Found 'links:'!$(NC)" || echo "$(GREEN)No 'links:' found$(NC)"
	@grep -r -- "--link" $(SRCS_PATH) 2>/dev/null && echo "$(RED)Found '--link'!$(NC)" || echo "$(GREEN)No '--link' found$(NC)"
	@grep -r "tail -f" $(SRCS_PATH)/requirements 2>/dev/null && echo "$(RED)Found 'tail -f'!$(NC)" || echo "$(GREEN)No 'tail -f' found$(NC)"
	@grep -r "sleep infinity" $(SRCS_PATH)/requirements 2>/dev/null && echo "$(RED)Found 'sleep infinity'!$(NC)" || echo "$(GREEN)No 'sleep infinity' found$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)   Check Complete$(NC)"
	@echo "$(GREEN)========================================$(NC)"

# Setup hosts file
hosts:
	@bash $(SRCS_PATH)/requirements/tools/setup_hosts.sh

# Troubleshooting
troubleshoot:
	@bash $(SRCS_PATH)/requirements/tools/troubleshoot.sh

# Debug tool
debug:
	@bash $(SRCS_PATH)/requirements/tools/debug.sh

# Cleanup tool
cleanup:
	@bash $(SRCS_PATH)/requirements/tools/cleanup.sh

# Evaluation check
eval-check:
	@bash $(SRCS_PATH)/requirements/tools/evaluation_check.sh

# Help target
help:
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(BLUE)   Inception Makefile Help$(NC)"
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(CYAN)Available targets:$(NC)"
	@echo "  $(GREEN)all$(NC)           - Build and start all services (default)"
	@echo "  $(GREEN)up$(NC)            - Build and start all services"
	@echo "  $(GREEN)down$(NC)          - Stop and remove all containers"
	@echo "  $(GREEN)stop$(NC)          - Stop all containers"
	@echo "  $(GREEN)start$(NC)         - Start stopped containers"
	@echo "  $(GREEN)restart$(NC)       - Restart all services"
	@echo "  $(GREEN)build$(NC)         - Build Docker images"
	@echo "  $(GREEN)logs$(NC)          - Show logs for all services"
	@echo "  $(GREEN)logs-SERVICE$(NC)  - Show logs for specific service"
	@echo "  $(GREEN)ps$(NC)            - Show container status"
	@echo "  $(GREEN)clean$(NC)         - Remove containers and images"
	@echo "  $(GREEN)fclean$(NC)        - Complete cleanup including data"
	@echo "  $(GREEN)re$(NC)            - Rebuild everything from scratch"
	@echo "  $(GREEN)info$(NC)          - Display configuration"
	@echo "  $(GREEN)check$(NC)         - Check evaluation requirements"
	@echo "  $(GREEN)shell-SERVICE$(NC) - Shell access to service"
	@echo "  $(GREEN)db$(NC)            - Access MariaDB console"
	@echo "  $(GREEN)wp$(NC)            - WordPress CLI commands"
	@echo "  $(GREEN)help$(NC)          - Show this help message"
	@echo "$(BLUE)========================================$(NC)"

# Prevent make from interpreting extra arguments as targets
%:
	@:

.PHONY: all up down stop start restart build logs ps clean fclean re \
        create_dirs check_env info check help shell-nginx shell-wordpress \
        shell-mariadb db wp hosts troubleshoot debug cleanup eval-check
