#!/bin/sh
set -e

echo PATATA

# Lee la plantilla fija y genera el .conf final usando el nombre del dominio dinámico
envsubst '${DOMAIN}' < /etc/nginx/wordpress.template > /etc/nginx/sites-enabled/${DOMAIN}.conf

# Eliminar el default residual
rm -f /etc/nginx/sites-enabled/default

exec nginx -g "daemon off;"
