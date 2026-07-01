# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: pabmart2 <pabmart2@student.42malaga.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2024/09/20 14:34:30 by pabmart2          #+#    #+#              #
#    Updated: 2026/07/01 18:02:21 by pabmart2         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

include srcs/.env
export

NAME = inception

all: $(NAME)

setup:
	@mkdir -p $(DB_DIR)
	@mkdir -p $(WP_DIR)

$(NAME): setup down
	@docker compose -f srcs/docker-compose.yml up -d

down:
	@docker compose -f srcs/docker-compose.yml down

clean:
	@IMAGES=$$(docker compose -f srcs/docker-compose.yml images -q); \
	docker compose -f srcs/docker-compose.yml down; \
	if [ -n "$$IMAGES" ]; then docker rmi $$IMAGES; fi

fclean: clean
	@rm -rf $(DB_DIR)
	@rm -rf $(WP_DIR)

re: fclean
	@$(MAKE) --no-print-directory all

.PHONY: all clean fclean re setup down
