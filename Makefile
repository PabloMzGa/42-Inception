# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: pablo <pablo@student.42.fr>                +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2024/09/20 14:34:30 by pabmart2          #+#    #+#              #
#    Updated: 2026/07/08 02:22:16 by pablo            ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

include srcs/.env
export

NAME = inception

all: $(NAME)

setup:
	@mkdir -p $(DB_DIR)
	@mkdir -p $(WP_DIR)

$(NAME): setup
	@docker compose -f srcs/docker-compose.yml up -d --build

# Regla base que acepta modificadores externos
down:
	@docker compose -f srcs/docker-compose.yml down $(FLAGS)

clean:
	@echo "🧹 Limpiando contenedores e imágenes..."
	# --rmi all borra todas las imágenes asociadas al compose, pero mantiene volúmenes
	@$(MAKE) --no-print-directory down FLAGS="--rmi all"

fclean: clean
	@echo "🔥 Eliminando VOLÚMENES NOMBRADOS de Docker..."
	# --volumes borra los volúmenes de Docker de la memoria
	@$(MAKE) --no-print-directory down FLAGS="--volumes"

	@echo "📂 Eliminando carpetas físicas del host con sudo..."
	@if [ -d "$(DB_DIR)" ]; then sudo rm -rf $(DB_DIR); fi
	@if [ -d "$(WP_DIR)" ]; then sudo rm -rf $(WP_DIR); fi
	@echo "✨ Sistema completamente limpio."

re: clean
	@$(MAKE) --no-print-directory all

fre: fclean
	@$(MAKE) --no-print-directory all

.PHONY: all clean fclean re fre setup down
