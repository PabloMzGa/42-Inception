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
# SECRETS LIST
# ------------------------------------------------------------------------------
SECRETS = \
    db_host.txt \
    db_name.txt \
    db_pass.txt \
    db_user.txt \
    wp_admin_email.txt \
    wp_admin_pass.txt \
    wp_admin_user.txt \
    wp_user_email.txt \
    wp_user_pass.txt \
    wp_user.txt

# ------------------------------------------------------------------------------
# RULES
# ------------------------------------------------------------------------------
all: $(NAME)


check-secrets:
	@echo "$(CLR_YELLOW)🔍 Checking Docker secrets...$(CLR_RESET)"
	@mkdir -p secrets
	@missing=0; \
	for s in $(SECRETS); do \
		file="secrets/$$s"; \
		if [ ! -e "$$file" ]; then \
			touch "$$file"; \
			chmod 600 "$$file"; \
			echo "   $(CLR_YELLOW)⚠️  Created (empty): $$file$(CLR_RESET)"; \
			missing=1; \
		elif [ ! -s "$$file" ]; then \
			echo "   $(CLR_RED)❌ Empty: $$file$(CLR_RESET)"; \
			missing=1; \
		else \
			echo "   $(CLR_GREEN)✅ OK: $$file$(CLR_RESET)"; \
		fi; \
	done; \
	if [ $$missing -eq 1 ]; then \
		echo "$(CLR_RED)⚠️  Some secrets are missing or empty. Please fill them before running 'make'.$(CLR_RESET)"; \
	else \
		echo "$(CLR_GREEN)✨ All secrets are configured!$(CLR_RESET)"; \
	fi


# 1. Validate that all secrets are filled
validate-secrets: check-secrets
	@echo "$(CLR_YELLOW)📋 Validating secrets...$(CLR_RESET)"
	@missing=0; \
	for s in $(SECRETS); do \
		file="secrets/$$s"; \
		if [ ! -s "$$file" ]; then missing=1; fi; \
	done; \
	if [ $$missing -eq 1 ]; then \
		echo "$(CLR_RED)❌ Cannot proceed: Some secrets are empty!$(CLR_RESET)"; \
		exit 1; \
	else \
		echo "$(CLR_GREEN)✅ All secrets validated successfully!$(CLR_RESET)"; \
	fi

# 2. Create necessary directories on the host
setup: validate-secrets
	@echo "$(CLR_YELLOW)⚙️  Creating host directories...$(CLR_RESET)"
	@sudo mkdir -p $(DB_DIR)
	@sudo mkdir -p $(WP_DIR)

# 3. Build docker images (uses cache by default unless specified)
build:
	@echo "$(CLR_YELLOW)🛠️  Building docker images...$(CLR_RESET)"
	@$(DOCKER_COMPOSE) build $(BUILD_FLAGS)

# 4. Launch already built containers
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

# Cleans containers and images, but keeps volumes
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
	@if [ -d "$(DB_DIR)" ]; then sudo rm -rf $(DB_DIR); fi
	@if [ -d "$(WP_DIR)" ]; then sudo rm -rf $(WP_DIR); fi
	@echo "$(CLR_RED)💥 Environment fully purged and reset.$(CLR_RESET)"

# Quick recompile (keeps volumes) forcing a real NO-CACHE build
re: clean
	@$(MAKE) --no-print-directory build BUILD_FLAGS="--no-cache"
	@$(MAKE) --no-print-directory up

# Full purge recompile (deletes volumes)
fre: fclean all

.PHONY: all clean fclean re fre setup down build up
