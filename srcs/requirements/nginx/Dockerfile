FROM debian:12

# =========================================================
# 1. INSTALL REQUIRED TOOLS AND DEPENDENCIES
# =========================================================
# Install Nginx, OpenSSL for TLS, and gettext-base for the envsubst utility
RUN apt update && apt install -y nginx openssl gettext-base && apt clean && \
    rm -rf /var/lib/apt/lists/*

# Create the dedicated directory to store secure SSL certificates
RUN mkdir -p /etc/nginx/ssl

# =========================================================
# 2. BUILD ARGUMENTS AND SSL GENERATION
# =========================================================
# Receive the domain variable passed from docker-compose.yml during build time
ARG DOMAIN

# Generate a self-signed SSL/TLS certificate using the dynamic ${DOMAIN} as the Common Name (CN)
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=ES/ST=Andalucia/L=Malaga/O=42/OU=42Malaga/CN=${DOMAIN}"

# =========================================================
# 3. CONFIGURATION FILES AND SCRIPTS DEPLOYMENT
# =========================================================
# Copy the primary global Nginx configuration file
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy the server configuration file into an internal template for dynamic runtime substitution
COPY conf/sites-enabled/wordpress.template /etc/nginx/wordpress.template

# Copy and grant execution permissions to the initialization entrypoint script
COPY tools/ng-init.sh /usr/local/bin/ng-init.sh
RUN chmod +x /usr/local/bin/ng-init.sh

# =========================================================
# 4. NETWORK AND ENTRYPOINT
# =========================================================
# Expose the standard secure HTTPS port as strictly required by Inception
EXPOSE 443

# Execute the initialization script as the container entrypoint
ENTRYPOINT ["/usr/local/bin/ng-init.sh"]
