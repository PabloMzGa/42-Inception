#!/bin/sh

set -e

# ---------------------------------------------------------
# 0. Leer secretos desde /run/secrets
# ---------------------------------------------------------
cat /run/secrets/db_user
cat /run/secrets/db_pass
cat /run/secrets/db_name
cat /run/secrets/db_host


MYSQL_USER=$(cat /run/secrets/db_user | tr -d '\r\n')
MYSQL_PASSWORD=$(cat /run/secrets/db_pass | tr -d '\r\n')
MYSQL_DATABASE=$(cat /run/secrets/db_name | tr -d '\r\n')
MYSQL_HOST=$(cat /run/secrets/db_host 2>/dev/null | tr -d '\r\n' || echo "db")

# ---------------------------------------------------------
# 1. Esperar a que MariaDB esté accesible
# ---------------------------------------------------------
echo "⏳ Esperando a MariaDB en ${MYSQL_HOST}..."
until mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" --password="${MYSQL_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; do
    echo "⏳ Esperando a MariaDB en ${MYSQL_HOST}..."
    sleep 1
done
echo "✔ MariaDB está accesible"

# ---------------------------------------------------------
# 2. Crear wp-config.php si no existe
# ---------------------------------------------------------
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "⚙️ Generando wp-config.php..."

    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

    sed -i "s/database_name_here/${MYSQL_DATABASE}/" /var/www/html/wp-config.php
    sed -i "s/username_here/${MYSQL_USER}/" /var/www/html/wp-config.php
    sed -i "s/password_here/${MYSQL_PASSWORD}/" /var/www/html/wp-config.php
    sed -i "s/localhost/${MYSQL_HOST}/" /var/www/html/wp-config.php

    # Claves de seguridad
    curl -s https://api.wordpress.org/secret-key/1.1/salt/ \
        | sed -i "/AUTH_KEY/d;/SECURE_AUTH_KEY/d;/LOGGED_IN_KEY/d;/NONCE_KEY/d;/AUTH_SALT/d;/SECURE_AUTH_SALT/d;/LOGGED_IN_SALT/d;/NONCE_SALT/d" \
        && curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/html/wp-config.php

    echo "✔ wp-config.php generado"
fi

# ---------------------------------------------------------
# 3. Permisos correctos
# ---------------------------------------------------------
echo "🔧 Ajustando permisos..."
chown -R www-data:www-data /var/www/html

# ---------------------------------------------------------
# 4. Arrancar PHP-FPM en foreground
# ---------------------------------------------------------
echo "🚀 Arrancando PHP-FPM..."
exec php-fpm8.2 -F
