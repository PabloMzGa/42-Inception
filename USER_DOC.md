# User Documentation

## What This Project Provides

Inception deploys a small WordPress infrastructure made of three services:

- Nginx acts as the public entry point and serves the website over HTTPS.
- WordPress runs with PHP-FPM and handles the application logic.
- MariaDB stores the WordPress database.

The stack is designed so the services run in separate containers, communicate over a Docker network, and keep their data after restarts.

## Start and Stop the Project

From the repository root, start the stack with:

```bash
make
```

This command checks the secrets, creates the host data directories, builds the images, and starts the containers.

If secrets aren't set up, it will generate the "secrets" folder with all the empty files. Fill them and then execute again.

To start an already built stack:

```bash
make up
```

To stop the stack:

```bash
make down
```

Useful cleanup commands:

```bash
make clean
make fclean
make re
```

- `make clean` removes containers and local image layers.
- `make fclean` removes containers, images, Docker volumes, and the host data directories.
- `make re` rebuilds the project without cache and restarts it.

## Access the Website and Administration Panel

The configured domain is defined in `srcs/.env` through the `LOGIN` variable, which is used to build a domain such as `pabmart2.42.fr`.

Because `<login>.42.fr` is not a public DNS record, you must map it to your local IP in your operating system's hosts file before opening the site. Make sure the login used there matches the `LOGIN` value in `srcs/.env` exactly. The exact setup details are documented in `DEV_DOC.md`.

- Website: `https://<login>.42.fr`
- WordPress administration panel: `https://<login>.42.fr/wp-admin`

The website uses a self-signed certificate, so your browser may show a warning the first time you open it.

## Credentials

Credentials are stored as Docker secret files in the `secrets/` directory at the repository root.

Main secret files:

- `secrets/db_name.txt`
- `secrets/db_user.txt`
- `secrets/db_pass.txt`
- `secrets/wp_admin_user.txt`
- `secrets/wp_admin_pass.txt`
- `secrets/wp_admin_email.txt`
- `secrets/wp_user.txt`
- `secrets/wp_user_pass.txt`
- `secrets/wp_user_email.txt`

To manage credentials:

- Fill each file with the expected value before starting the stack.
- Run `make check-secrets` to verify that the files exist and are not empty.
- Avoid putting passwords directly in Dockerfiles, Compose files, or the README.

## Check That the Services Are Running Correctly

You can verify the stack with these checks:

```bash
docker compose -f srcs/docker-compose.yml ps
```

This shows whether the containers are running.

You can also confirm the website responds over HTTPS:

```bash
curl -k https://<login>.42.fr
```

For a full browser check, open the website and the `/wp-admin` page.

## Data Location

The persistent data is stored on the host under `/home/<login>/data`.

- WordPress files: `/home/<login>/data/wp`
- MariaDB data: `/home/<login>/data/db`

These paths let the data survive container rebuilds and restarts.
