# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: na-kannan <na-kannan@student.42.fr>        +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2024/08/09 20:00:00 by na-kannan         #+#    #+#              #
#    Updated: 2024/08/09 20:00:00 by na-kannan        ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME = inception

# Paths
SRCS_PATH = ./srcs
DOCKER_COMPOSE = docker compose
DOCKER_COMPOSE_FILE = $(SRCS_PATH)/docker-compose.yml
DATA_PATH = /home/$(USER)/data

# Colors
GREEN = \033[0;32m
RED = \033[0;31m
NC = \033[0m

all: up

up: create_dirs
	@echo "$(GREEN)Starting containers...$(NC)"
	$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) up -d --build
	@echo "$(GREEN)Inception is running!$(NC)"

down:
	@echo "$(RED)Stopping containers...$(NC)"
	$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) down

stop:
	@echo "$(RED)Stopping containers...$(NC)"
	$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) stop

start:
	@echo "$(GREEN)Starting containers...$(NC)"
	$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) start

restart: down up

logs:
	$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) logs -f

ps:
	$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) ps

clean: down
	@echo "$(RED)Removing containers...$(NC)"
	$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) down --rmi all --volumes --remove-orphans

fclean: clean
	@echo "$(RED)Removing all Docker data...$(NC)"
	@docker system prune -af --volumes
	@sudo rm -rf $(DATA_PATH)/wordpress
	@sudo rm -rf $(DATA_PATH)/mariadb
	@echo "$(GREEN)Cleanup complete!$(NC)"

re: fclean all

create_dirs:
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@echo "$(GREEN)Data directories created!$(NC)"

.PHONY: all up down stop start restart logs ps clean fclean re create_dirs
