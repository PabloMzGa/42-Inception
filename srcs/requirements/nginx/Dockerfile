FROM debian:12

# Instalar herramientas necesarias
RUN apt update && apt install -y nginx openssl gettext-base && apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

# ---------------------------------------------------------
# RECIBIR LA VARIABLE DESDE EL DOCKER COMPOSE
# ---------------------------------------------------------
ARG DOMAIN

# Ahora usamos ${DOMINIO} dinámicamente en el Common Name (CN) del certificado
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=ES/ST=Andalucia/L=Malaga/O=42/OU=42Malaga/CN=${DOMAIN}"

# ---------------------------------------------------------
# Configuración de archivos y scripts
# ---------------------------------------------------------
COPY conf/nginx.conf /etc/nginx/nginx.conf
# Copias el archivo con su nombre físico fijo, pero lo guardas como la plantilla interna
COPY conf/sites-enabled/wordpress.template /etc/nginx/wordpress.template

COPY tools/ng-init.sh /usr/local/bin/ng-init.sh
RUN chmod +x /usr/local/bin/ng-init.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/ng-init.sh"]
