#!/bin/sh

set -e

# ---------------------------------------------------------
# 0. Leer secretos desde /run/secrets
# ---------------------------------------------------------
MYSQL_USER=$(cat /run/secrets/db_user | tr -d '\r\n')
MYSQL_PASSWORD=$(cat /run/secrets/db_pass | tr -d '\r\n')
MYSQL_DATABASE=$(cat /run/secrets/db_name | tr -d '\r\n')
MYSQL_HOST=$(cat /run/secrets/db_host 2>/dev/null | tr -d '\r\n' || echo "db")

# Variables para WordPress (Es mejor leerlas de secretos/env también)
WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user | tr -d '\r\n')
WP_ADMIN_PASS=$(cat /run/secrets/wp_admin_pass | tr -d '\r\n')
WP_ADMIN_EMAIL=$(cat /run/secrets/wp_admin_email | tr -d '\r\n')

WP_USER=$(cat /run/secrets/wp_user | tr -d '\r\n')
WP_USER_PASS=$(cat /run/secrets/wp_user_pass | tr -d '\r\n')
WP_USER_EMAIL=$(cat /run/secrets/wp_user_email | tr -d '\r\n')

# Nos movemos al directorio de WordPress para que wp-cli sepa dónde trabajar
cd /var/www/html

# ---------------------------------------------------------
# 1. Esperar a que MariaDB esté accesible
# ---------------------------------------------------------
echo "⏳ Esperando a MariaDB en ${MYSQL_HOST}..."
until mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" --password="${MYSQL_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; do
    sleep 1
done
echo "✔ MariaDB está accesible"

# ---------------------------------------------------------
# 2. Descargar WordPress (Por si el volumen está vacío)
# ---------------------------------------------------------
if [ ! -f "wp-load.php" ]; then
    echo "📥 Descargando WordPress..."
    wp core download --allow-root
fi

# ---------------------------------------------------------
# 3. Crear wp-config.php de forma nativa con wp-cli
# ---------------------------------------------------------
if [ ! -f "wp-config.php" ]; then
    echo "⚙️ Generando wp-config.php de forma segura..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOST}" \
        --allow-root
fi

# ---------------------------------------------------------
# 4. Instalación Core y Automatización de Usuarios + Temas
# ---------------------------------------------------------
# Comprobamos si WordPress ya está instalado en la Base de Datos
if ! wp core is-installed --allow-root; then
    echo "🚀 Instalando WordPress..."

    # A) Instalación principal y creación del Administrador (¡SIN la palabra admin!)
    wp core install \
        --url="pabmart2.42.fr" \
        --title="Inception - pabmart2" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "✔ Administrador de WordPress creado con éxito."

    # B) Creación del Segundo Usuario Obligatorio (Rol de autor/editor)
    echo "👤 Creando el segundo usuario..."
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASS}" \
        --allow-root

    echo "✔ Segundo usuario creado."

    # C) Automatización: Descargar y activar una Plantilla (Tema)
    # Puedes usar el nombre de cualquier tema del repositorio de WordPress (ej: 'twentytwentyfour', 'astra', 'oceanwp')
    echo "🎨 Instalando y activando la plantilla Astra..."
    wp theme install astra --activate --allow-root

    # D) Opcional: Instalar plugins útiles (ej: Redis Cache, que te lo pedirán en el bonus)
    # wp plugin install redis-cache --activate --allow-root

    echo "🎉 ¡Todo el entorno de WordPress ha sido automatizado!"
fi

# ---------------------------------------------------------
# 5. Permisos correctos
# ---------------------------------------------------------
echo "🔧 Ajustando permisos de los archivos generados..."
chown -R www-data:www-data /var/www/html

# ---------------------------------------------------------
# 6. Arrancar PHP-FPM en foreground
# ---------------------------------------------------------
echo "🚀 Arrancando PHP-FPM..."
exec php-fpm8.2 -F
