FROM debian:12

# ---------------------------------------------------------
# 1. Actualizar e instalar MariaDB + herramientas necesarias
# ---------------------------------------------------------
RUN apt update && apt install -y \
    mariadb-server \
    mariadb-client \
    procps \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# 2. Crear directorios necesarios para MariaDB
# ---------------------------------------------------------
RUN mkdir -p /run/mysqld \
    && mkdir -p /var/lib/mysql \
    && chown -R mysql:mysql /run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql

# ---------------------------------------------------------
# 3. Copiar script de inicialización
# ---------------------------------------------------------
COPY tools/db-init.sh /usr/local/bin/db-init.sh
RUN chmod +x /usr/local/bin/db-init.sh

COPY conf/99-docker.cnf /etc/mysql/mariadb.conf.d/99-docker.cnf

# ---------------------------------------------------------
# 4. Exponer puerto de MariaDB
# ---------------------------------------------------------
EXPOSE 3306

# ---------------------------------------------------------
# 5. Ejecutar script de inicialización como ENTRYPOINT
# ---------------------------------------------------------
ENTRYPOINT ["/usr/local/bin/db-init.sh"]
