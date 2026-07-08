# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: pablo <pablo@student.42.fr>                +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2024/09/20 14:34:30 by pabmart2          #+#    #+#              #
#                                                 ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# ------------------------------------------------------------------------------
# AUTO-SUDO ENFORCEMENT
# ------------------------------------------------------------------------------
ifneq ($(shell id -u), 0)
all clean fclean re fre setup down build up:
	@sudo -E make --no-print-directory $@ $(MAKEFLAGS)
else

# ------------------------------------------------------------------------------
# CONFIGURATION & ENVIRONMENT
# ------------------------------------------------------------------------------
include srcs/.env
export

NAME            := inception
DOCKER_COMPOSE  := docker compose -f srcs/docker-compose.yml

# ANSI Color Codes for Clean Logging
CLR_RESET  := \033[0m
CLR_GREEN  := \033[32m
CLR_YELLOW := \033[33m
CLR_RED    := \033[31m

# ------------------------------------------------------------------------------
# RULES
# ------------------------------------------------------------------------------
all: $(NAME)

# 1. Create necessary directories on the host
setup:
	@echo "$(CLR_YELLOW)⚙️  Creating host directories...$(CLR_RESET)"
	@mkdir -p $(DB_DIR)
	@mkdir -p $(WP_DIR)

# 2. Build docker images (uses cache by default unless specified)
build:
	@echo "$(CLR_YELLOW)🛠️  Building docker images...$(CLR_RESET)"
	@$(DOCKER_COMPOSE) build $(BUILD_FLAGS)

# 3. Launch already built containers
up:
	@echo "$(CLR_YELLOW)🚀 Launching containers...$(CLR_RESET)"
	@$(DOCKER_COMPOSE) up -d
	@echo "$(CLR_GREEN)✅ $(NAME) is up and running!$(CLR_RESET)"

# Main target resolved cleanly using native Make dependencies
$(NAME): setup build up

# ------------------------------------------------------------------------------
# CLEANING & RESET
# ------------------------------------------------------------------------------
down:
	@$(DOCKER_COMPOSE) down $(FLAGS)

# Cleans containers and images, bu
clean:
	@echo "$(CLR_YELLOW)🧹 Removing containers and image layers...$(CLR_RESET)"
	@$(MAKE) --no-print-directory down FLAGS="--rmi all"
	@echo "$(CLR_GREEN)✨ Containers and local image layers cleaned.$(CLR_RESET)"

fclean: clean
	@echo "$(CLR_YELLOW)🔥 Removing persistent docker volumes...$(CLR_RESET)"
	@$(MAKE) --no-print-directory down FLAGS="--volumes"

	@echo "$(CLR_YELLOW)🧹 Purging Docker build cache...$(CLR_RESET)"
	@docker builder prune -f > /dev/null

	@echo "$(CLR_YELLOW)📂 Deleting physical host folders...$(CLR_RESET)"
	@if [ -d "$(DB_DIR)" ]; then rm -rf $(DB_DIR); fi
	@if [ -d "$(WP_DIR)" ]; then rm -rf $(WP_DIR); fi
	@echo "$(CLR_RED)💥 Environment fully purged and reset.$(CLR_RESET)"

# Quick recompile (keeps volumes) forcing a real NO-CACHE build
re: clean
	@$(MAKE) --no-print-directory build BUILD_FLAGS="--no-cache"
	@$(MAKE) --no-print-directory up

# Full purge recompile (deletes volumes)
fre: fclean all

.PHONY: all clean fclean re fre setup down build up
endif
