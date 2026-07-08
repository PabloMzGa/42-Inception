#!/bin/sh

set -e

# ---------------------------------------------------------
# 0. Leer secretos desde /run/secrets (Limpia \r y \n)
# ---------------------------------------------------------
MYSQL_USER=$(cat /run/secrets/db_user | tr -d '\r\n')
MYSQL_PASSWORD=$(cat /run/secrets/db_pass | tr -d '\r\n')
MYSQL_DATABASE=$(cat /run/secrets/db_name | tr -d '\r\n')

echo "🚀 Iniciando script de configuración de MariaDB..."

# ---------------------------------------------------------
# 1. Comprobar que el volumen está montado en /var/lib/mysql
# ---------------------------------------------------------
if [ ! -d "/var/lib/mysql" ]; then
    echo "❌ ERROR: El volumen no está montado en /var/lib/mysql."
    exit 1
fi

# ---------------------------------------------------------
# 2. Inicializar sistema de tablas básico si no existe
# ---------------------------------------------------------
# Esto asegura que la base de datos del sistema está instalada si el volumen viene virgen,
# pero no interfiere con la creación posterior de tu usuario customizado.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "⚙️ Creando tablas del sistema de MariaDB..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# ---------------------------------------------------------
# 3. Arrancar MariaDB temporalmente sin red para verificar/configurar
# ---------------------------------------------------------
echo "⏳ Arrancando MariaDB temporal para chequeo de seguridad..."
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
TEMP_PID=$!

# ---------------------------------------------------------
# 4. Esperar a que el servidor temporal arranque
# ---------------------------------------------------------
while ! mysqladmin ping --silent; do
    sleep 1
done

# ---------------------------------------------------------
# 5. CHECK REAL: ¿Existe la DB y el usuario funciona?
# ---------------------------------------------------------
# Intentamos usar la base de datos con las credenciales que pasamos por secretos.
# Si el comando tiene éxito (devuelve 0), significa que ya está todo configurado en el volumen.
if mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "USE \`${MYSQL_DATABASE}\`;" >/dev/null 2>&1; then
    echo "🎉 Check completado: El usuario y la base de datos ya existen y están operativos."
    echo "🛑 Apagando servidor temporal..."
    mysqladmin shutdown

    echo "🚀 Arrancando MariaDB definitivo en foreground..."
    exec su mysql -s /bin/sh -c "mysqld"
fi

# ---------------------------------------------------------
# 6. Si el check falló: Crear base de datos, usuario y privilegios
# ---------------------------------------------------------
echo "⚙️ El check falló o es el primer arranque. Configurando base de datos de Inception..."

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# ---------------------------------------------------------
# 7. Parar MariaDB temporal de forma limpia
# ---------------------------------------------------------
echo "🛑 Configuración aplicada. Apagando servidor temporal..."
mysqladmin shutdown

echo "✔ Inicialización completada con éxito."
echo "🚀 Arrancando MariaDB definitivo en foreground como usuario mysql..."

# ---------------------------------------------------------
# 8. Arrancar MariaDB en foreground como usuario mysql
# ---------------------------------------------------------
exec su mysql -s /bin/sh -c "mysqld"
