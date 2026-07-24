#!/bin/sh

set -e

# =========================================================
# 0. READ SECRETS AND ENVIRONMENT VARIABLES
# =========================================================
# Read database credentials from Docker secrets (Cleans \r and \n)
MYSQL_USER=$(cat /run/secrets/db_user | tr -d '\r\n')
MYSQL_PASSWORD=$(cat /run/secrets/db_pass | tr -d '\r\n')
MYSQL_DATABASE=$(cat /run/secrets/db_name | tr -d '\r\n')

# Read WordPress credentials from Docker secrets
WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user | tr -d '\r\n')
WP_ADMIN_PASS=$(cat /run/secrets/wp_admin_pass | tr -d '\r\n')
WP_ADMIN_EMAIL=$(cat /run/secrets/wp_admin_email | tr -d '\r\n')

WP_USER=$(cat /run/secrets/wp_user | tr -d '\r\n')
WP_USER_PASS=$(cat /run/secrets/wp_user_pass | tr -d '\r\n')
WP_USER_EMAIL=$(cat /run/secrets/wp_user_email | tr -d '\r\n')

# Navigate to the WordPress root directory so wp-cli targets the correct path
cd /var/www/html

echo "🚀 Starting WordPress initialization script..."

# =========================================================
# 1. WAIT FOR MARIADB ACCESSIBILITY
# =========================================================
# Loop until the database container is up, configured, and accepting connections
echo "⏳ Waiting for MariaDB at ${MYSQL_HOST}..."
until mysql -h"mariadb" -u"${MYSQL_USER}" --password="${MYSQL_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; do
    sleep 1
done
echo "✔ MariaDB is accessible"

# =========================================================
# 2. DOWNLOAD WORDPRESS CORE
# =========================================================
# Downloads the core files only if the mounted volume is currently empty
if [ ! -f "wp-load.php" ]; then
    echo "📥 Downloading WordPress core files..."
    wp core download --allow-root
fi

# =========================================================
# 3. GENERATE WP-CONFIG.PHP
# =========================================================
# Securely builds the native wp-config.php file using wp-cli
if [ ! -f "wp-config.php" ]; then
    echo "⚙️ Generating wp-config.php securely..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOST}" \
        --allow-root
fi

# =========================================================
# 4. CORE INSTALLATION AND AUTOMATION (USERS & THEMES)
# =========================================================
# Check if WordPress is already installed inside the database schema
if ! wp core is-installed --allow-root; then
    echo "🚀 Installing WordPress database tables..."

    # ---------------------------------------------------------
    # A) Main installation and Administrator creation
    # ---------------------------------------------------------
    # Strict 42 security rule: Do NOT use 'admin' or 'administrator' as the username!
    wp core install \
        --url="${DOMAIN}" \
        --title="Inception - pabmart2" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "✔ WordPress Administrator account created successfully."

    # ---------------------------------------------------------
    # B) Second mandatory user creation
    # ---------------------------------------------------------
    # Creates the regular non-admin user required by the subject (Author/Editor role)
    echo "👤 Creating the second regular user..."
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASS}" \
        --allow-root

    echo "✔ Second user created successfully."

    # ---------------------------------------------------------
    # C) Theme deployment automation
    # ---------------------------------------------------------
    # Installs and activates a clean, lightweight theme from the WordPress repository
    echo "🎨 Installing and activating the Astra theme..."
    wp theme install astra --activate --allow-root

    # ---------------------------------------------------------
    # D) Optional Bonus Plugins
    # ---------------------------------------------------------
    # Uncomment if you are implementing the Redis Cache bonus feature
    # wp plugin install redis-cache --activate --allow-root

    echo "🎉 WordPress environment has been fully automated and configured!"
fi

# =========================================================
# 5. FILE PERMISSIONS ADJUSTMENT
# =========================================================
# Recursively sets proper ownership so Nginx/PHP-FPM can modify files safely
echo "🔧 Adjusting permissions for the generated core files..."
chown -R www-data:www-data /var/www/html

# =========================================================
# 6. LAUNCH PHP-FPM
# =========================================================
# Runs PHP-FPM daemon in the foreground (-F) to keep the container active
echo "🚀 Starting PHP-FPM in the foreground..."
exec php-fpm8.2 -F
