#!/bin/sh
set -e

echo "🚀 Starting Nginx configuration script..."

# ---------------------------------------------------------
# 1. Generate the final configuration from the template
# ---------------------------------------------------------
# Reads the fixed template and generates the final .conf file using the dynamic domain name
envsubst '${DOMAIN}' < /etc/nginx/wordpress.template > /etc/nginx/sites-enabled/${DOMAIN}.conf

# ---------------------------------------------------------
# 2. Remove residual default configurations
# ---------------------------------------------------------
# Deletes the default Nginx configuration file to prevent conflicts
rm -f /etc/nginx/sites-enabled/default

# ---------------------------------------------------------
# 3. Launch Nginx in the foreground
# ---------------------------------------------------------
exec nginx -g "daemon off;"
