# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: pablo <pablo@student.42.fr>                +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2024/09/20 14:34:30 by pabmart2          #+#    #+#              #
#    Updated: 2026/07/07 14:06:28 by pablo            ###   ########.fr        #
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

down:
	@docker compose -f srcs/docker-compose.yml down

clean:
	@echo "🧹 Limpiando contenedores e imágenes (volúmenes se conservan)..."
	@docker compose -f srcs/docker-compose.yml down

	@echo "🗑️ Borrando imágenes..."
	@docker rmi $(NGINX_IMAGE) $(MARIADB_IMAGE) $(WORDPRESS_IMAGE) || true

fclean: clean
	@echo "🔥 Limpiando volúmenes y carpetas del host..."
	@docker compose -f srcs/docker-compose.yml down --volumes

	@for VOL in $$(docker volume ls -q | grep $(NAME)); do \
		docker volume rm $$VOL; \
	done

	@rm -rf $(DB_DIR)
	@rm -rf $(WP_DIR)

re: clean
	@$(MAKE) --no-print-directory all

fre: fclean
	@$(MAKE) --no-print-directory all

.PHONY: all clean fclean re fre setup down
