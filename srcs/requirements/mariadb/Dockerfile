FROM debian:12

# ---------------------------------------------------------
# 1. Update and install MariaDB + required tools
# ---------------------------------------------------------
RUN apt update && apt install -y \
    mariadb-server \
    mariadb-client \
    procps \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# 2. Create required directories for MariaDB
# ---------------------------------------------------------
RUN mkdir -p /run/mysqld \
    && mkdir -p /var/lib/mysql \
    && chown -R mysql:mysql /run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql

# ---------------------------------------------------------
# 3. Copy initialization script
# ---------------------------------------------------------
COPY tools/db-init.sh /usr/local/bin/db-init.sh
RUN chmod +x /usr/local/bin/db-init.sh

COPY conf/99-docker.cnf /etc/mysql/mariadb.conf.d/99-docker.cnf

# ---------------------------------------------------------
# 4. Expose MariaDB port
# ---------------------------------------------------------
EXPOSE 3306

# ---------------------------------------------------------
# 5. Run initialization script as ENTRYPOINT
# ---------------------------------------------------------
ENTRYPOINT ["/usr/local/bin/db-init.sh"]
