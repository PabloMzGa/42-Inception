#!/bin/sh

set -e

# ---------------------------------------------------------
# 0. Read secrets from /run/secrets (Cleans \r and \n)
# ---------------------------------------------------------
MYSQL_USER=$(cat /run/secrets/db_user | tr -d '\r\n')
MYSQL_PASSWORD=$(cat /run/secrets/db_pass | tr -d '\r\n')
MYSQL_DATABASE=$(cat /run/secrets/db_name | tr -d '\r\n')

echo "🚀 Starting MariaDB configuration script..."

# ---------------------------------------------------------
# 1. Check that the volume is mounted at /var/lib/mysql
# ---------------------------------------------------------
if [ ! -d "/var/lib/mysql" ]; then
    echo "❌ ERROR: The volume is not mounted at /var/lib/mysql."
    exit 1
fi

# ---------------------------------------------------------
# 2. Initialize basic system tables if they do not exist
# ---------------------------------------------------------
# This ensures the system database is installed if the volume is empty,
# but does not interfere with the subsequent creation of your custom user.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "⚙️ Creating MariaDB system tables..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# ---------------------------------------------------------
# 3. Start MariaDB temporarily without networking for verification/configuration
# ---------------------------------------------------------
echo "⏳ Starting temporary MariaDB for security check..."
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
TEMP_PID=$!

# ---------------------------------------------------------
# 4. Wait for the temporary server to start
# ---------------------------------------------------------
while ! mysqladmin ping --silent; do
    sleep 1
done

# ---------------------------------------------------------
# 5. Checks for the DB and correct user

# ---------------------------------------------------------
# We try to use the database with the credentials passed via secrets.
# If the command succeeds (returns 0), it means everything is already configured in the volume.
if mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "USE \`${MYSQL_DATABASE}\`;" >/dev/null 2>&1; then
    echo "🎉 Check completed: The user and database already exist and are operational."
    echo "🛑 Shutting down temporary server..."
    mysqladmin shutdown

    echo "🚀 Starting definitive MariaDB in the foreground..."
    exec su mysql -s /bin/sh -c "mysqld"
fi

# ---------------------------------------------------------
# 6. If the check failed: Create database, user, and privileges
# ---------------------------------------------------------
echo "⚙️ The check failed or this is the first boot. Configuring Inception database..."

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# ---------------------------------------------------------
# 7. Stop temporary MariaDB cleanly
# ---------------------------------------------------------
echo "🛑 Configuration applied. Shutting down temporary server..."
mysqladmin shutdown

echo "✔ Initialization completed successfully."
echo "🚀 Starting definitive MariaDB in the foreground as mysql user..."

# ---------------------------------------------------------
# 8. Start MariaDB in the foreground as mysql user
# ---------------------------------------------------------
exec su mysql -s /bin/sh -c "mysqld"
