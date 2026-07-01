#!/bin/sh

set -e # Strict mode, script will stop if any command returns non 0 code

# Checks if db is already initialized
if [ -d "/var/lib/mysql/mysql" ]; then
    echo "MariaDB already initialized, executing database server..."
    exec mysqld
fi

echo "Inicializando MariaDB..."

# Inicializar sistema de tablas
mysql_install_db --user=mysql --datadir=/var/lib/mysql

# Arrancar MariaDB temporalmente
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
TEMP_PID=$!

# Esperar a que arranque
while ! mysqladmin ping --silent; do
    sleep 1
done

echo "MariaDB temporal arrancado, creando base de datos..."

# Crear base de datos, usuario y permisos
mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Parar MariaDB temporal
mysqladmin shutdown

echo "Inicialización completada, arrancando MariaDB en modo servidor..."

# Arrancar MariaDB en foreground
exec su mysql -s /bin/sh -c "mysqld"



