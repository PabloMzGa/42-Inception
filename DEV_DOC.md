# Developer Documentation

## Environment Setup From Scratch

### Prerequisites

You need:

- Docker Engine
- Docker Compose v2
- A Linux environment with permission to create directories under `/home/<login>/data`

### Configuration Files

The main configuration files are:

- `srcs/.env` for environment variables used by Makefile and Docker Compose
- `srcs/docker-compose.yml` for the service definitions, secrets, networks, and persistent storage
- `Makefile` for build, run, stop, and cleanup commands
- `secrets/` for runtime credentials

### Local Domain Resolution

The project domain is built from the `LOGIN` variable in `srcs/.env`, so the final domain is `<login>.42.fr`. It is not backed by a public DNS record, so to access the website from your machine you must add a local hosts entry that points the domain to your local address.

Replace `<login>` with your learner username.

Make sure the `LOGIN` value in `srcs/.env` and the domain written in `/etc/hosts` are exactly the same, including every character.

On Linux, edit `/etc/hosts` with root privileges and add a line similar to:

```text
127.0.0.1 <login>.42.fr
```

If your setup uses a virtual machine instead of the local host, replace `127.0.0.1` with the VM IP address.

`srcs/.env` defines:

- `LOGIN=<login>`
- `DATA_DIR=/home/${LOGIN}/data`
- `DB_DIR=${DATA_DIR}/db`
- `WP_DIR=${DATA_DIR}/wp`
- `DOMAIN=${LOGIN}.42.fr`

Set `LOGIN` to your learner username before launching the project.

### Secrets

The project expects these secret files in `secrets/`:

- `db_name.txt`
- `db_pass.txt`
- `db_user.txt`
- `wp_admin_email.txt`
- `wp_admin_pass.txt`
- `wp_admin_user.txt`
- `wp_user_email.txt`
- `wp_user_pass.txt`
- `wp_user.txt`

Use `make check-secrets` to create missing files and detect empty ones. Populate each file before launching the stack.

## Build and Launch

The standard workflow is:

```bash
make
```

This target runs the full setup sequence:

1. Validate secrets.
2. Create the host data directories.
3. Build the Docker images.
4. Start the containers.

Other useful commands:

```bash
make build
make up
make down
make re
make clean
make fclean
make fre
```

- `make build` builds the images using the current Dockerfiles.
- `make up` starts the stack.
- `make down` stops the stack.
- `make re` rebuilds without cache and restarts the stack.
- `make clean` removes containers and local image layers.
- `make fclean` removes containers, images, volumes, and the host data directories.
- `make fre` performs a full cleanup and then rebuilds from scratch.

## Docker Compose and Images

The stack is defined in `srcs/docker-compose.yml` and contains three services:

- `nginx`
- `mariadb`
- `wordpress`

Each service runs in its own container and uses a dedicated Docker image built from the repository source.

The image build contexts are:

- `srcs/requirements/nginx/`
- `srcs/requirements/mariadb/`
- `srcs/requirements/wordpress/`

The services communicate through Docker networks defined in Compose. Nginx is the only public entry point, and the WordPress service connects to MariaDB through the private network.

## Persistent Data

The persistent data is stored in the host directory `/home/<login>/data`.

- MariaDB data directory: `/home/<login>/data/db`
- WordPress files directory: `/home/<login>/data/wp`

The Compose file defines two named volumes, `db_data` and `wp_data`, which are backed by those host paths. This means the data survives container recreation and rebuilds.

If you need to reset everything, `make fclean` removes the containers, the Docker volumes, and the host data directories.

## Managing Containers and Volumes

Useful commands during development:

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f
docker compose -f srcs/docker-compose.yml down --volumes
```

You can also inspect the configured volumes with:

```bash
docker volume ls
docker volume inspect inception_db_data
docker volume inspect inception_wp_data
```

If the volumes were created through Compose, the names may be prefixed by the project name.

## Data Persistence Notes

The stack keeps state in the MariaDB and WordPress storage paths on the host. Rebuilding the images does not erase the data.

Data is removed only when you explicitly clean it, for example with:

- `make fclean`
- `docker compose -f srcs/docker-compose.yml down --volumes`
- manual deletion of `/home/<login>/data`

## Checking the Result

After launch, verify the services with:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Then open the website over HTTPS and confirm that WordPress and the admin panel load correctly.
