*This project has been created as part of the 42 curriculum by pabmart2.*

# Inception

## Description

Inception is a Docker-based infrastructure project that deploys a complete WordPress stack with Nginx, MariaDB, and PHP-FPM. The goal is to build a small but realistic web environment where each service runs in its own container, communicates through Docker networks, and keeps its data across restarts.

The stack exposes WordPress through Nginx over HTTPS, stores the database and site files on Docker named volumes backed by /home/<login>/data on the host, and uses Docker secrets to keep credentials out of the images and the Compose file. The startup scripts automate the first boot so the database is created, WordPress is installed, the required users are added, and the web server is configured automatically.

## Project Description

This repository contains the full source needed to build and run the infrastructure:

- `Makefile` creates the host directories, validates secrets, builds the images, starts the stack, and cleans the environment.
- `srcs/docker-compose.yml` defines the three services, their networks, persistent named volumes, and Docker secrets.
- `srcs/requirements/nginx/` contains the reverse proxy image, TLS setup, and Nginx configuration.
- `srcs/requirements/mariadb/` contains the database image, MariaDB configuration, and database bootstrap script.
- `srcs/requirements/wordpress/` contains the PHP-FPM WordPress image, WP-CLI setup, and automatic site initialization.
- `secrets/` contains the sensitive values consumed by the containers at runtime.

Main design choices:

- Nginx is the public entry point and handles HTTPS termination with a self-signed certificate.
- WordPress runs behind Nginx through PHP-FPM on an internal network only.
- MariaDB is isolated on a private network and initialized from Docker secrets.
- Persistent data is stored outside the containers through Docker named volumes backed by the host data directory so the stack survives rebuilds and restarts.
- Initialization is scripted so the first boot creates the database, installs WordPress, creates the admin and regular user, and activates the Astra theme.

Comparison of the main technical choices:

- Virtual Machines vs Docker: VMs include a full guest operating system and are heavier to boot and maintain, while Docker shares the host kernel and gives a lighter, faster, and more portable deployment model for this project.
- Secrets vs Environment Variables: secrets are better for credentials because they are mounted at runtime and are not meant to be baked into images or exposed as plain environment values; environment variables remain useful for non-sensitive configuration such as the domain name or image names.
- Docker Network vs Host Network: a custom Docker network keeps the services isolated, provides name-based service discovery, and avoids exposing internal components directly to the host; host networking would remove that isolation and is unnecessary here.
- Docker Volumes vs Bind Mounts: named volumes are required here for the persistent storages, while direct bind mounts are not allowed for them; the volumes are backed by host directories under /home/<login>/data so the data survives container recreation while staying managed as Docker volumes.

## Instructions

Prerequisites:

- Docker Engine
- Docker Compose v2

Before starting the stack, make sure the secret files in `secrets/` contain the expected values and that `srcs/.env` points to valid host directories under `/home/<login>/data`.

The `LOGIN` variable in `srcs/.env` is the single source of truth for the host data path and the domain name. Set it to your learner username before running the project.

Optional preflight check:

```bash
make check-secrets
```

Run the project from the repository root:

```bash
make
```

This command validates the secrets, creates the host directories, builds the images, and starts the containers.

Useful targets:

- `make up` starts the already built stack.
- `make build` rebuilds the images.
- `make re` rebuilds without cache and restarts the stack.
- `make fre` rebuilds without cache, remove the volumes and restarts the stack
- `make clean` removes containers and local image layers.
- `make fclean` removes containers, images, volumes, and host data directories.
- `make down` stops the running stack.

Once the stack is up, open the configured domain in your browser over HTTPS.

## Resources

Classic references:

- Docker documentation: https://docs.docker.com/
- Docker Compose documentation: https://docs.docker.com/compose/
- Nginx documentation: https://nginx.org/en/docs/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- WordPress documentation: https://wordpress.org/documentation/
- WP-CLI documentation: https://developer.wordpress.org/cli/commands/

AI usage:

- AI was used to analyze the repository structure, solve and clarify technical questions, extract the behavior of the Compose file, Dockerfiles, and initialization scripts, and draft this README in English.
- AI was also used to organize the project description and technical comparisons so the documentation matches the actual implementation of the stack.
