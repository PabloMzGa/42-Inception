#!/bin/sh

set -e

# ---------------------------------------------------------
# 1. Comprobar que el volumen está montado en /var/lib/mysql
# ---------------------------------------------------------
if [ ! -d "/var/lib/mysql" ]; then
    echo "ERROR: El volumen no está montado en /var/lib/mysql."
    exit 1
fi

# ---------------------------------------------------------
# 2. Si MariaDB ya está inicializado, arrancar directamente
# ---------------------------------------------------------
if [ -d "/var/lib/mysql/mysql" ]; then
    echo "MariaDB already initialized, executing database server..."
    exec su mysql -s /bin/sh -c "mysqld"
fi

echo "Inicializando MariaDB..."

# ---------------------------------------------------------
# 3. Inicializar sistema de tablas
# ---------------------------------------------------------
mysql_install_db --user=mysql --datadir=/var/lib/mysql

# ---------------------------------------------------------
# 4. Arrancar MariaDB temporalmente sin red
# ---------------------------------------------------------
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
TEMP_PID=$!

# ---------------------------------------------------------
# 5. Esperar a que arranque
# ---------------------------------------------------------
while ! mysqladmin ping --silent; do
    sleep 1
done

echo "MariaDB temporal arrancado, creando base de datos..."

# ---------------------------------------------------------
# 6. Crear base de datos, usuario y permisos
# ---------------------------------------------------------
mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# ---------------------------------------------------------
# 7. Parar MariaDB temporal
# ---------------------------------------------------------
mysqladmin shutdown

echo "Inicialización completada, arrancando MariaDB en modo servidor..."

# ---------------------------------------------------------
# 8. Arrancar MariaDB en foreground como usuario mysql
# ---------------------------------------------------------
exec su mysql -s /bin/sh -c "mysqld"
