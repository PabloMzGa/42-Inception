FROM debian:12

RUN apt update && apt install -y nginx openssl && apt clean && \
	rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=ES/ST=Andalucia/L=Malaga/O=42/OU=42Malaga/CN=pabmart2.42.fr"

RUN rm -f /etc/nginx/sites-enabled/default

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/sites-enabled/pabmart2.42.fr.conf /etc/nginx/sites-enabled/pabmart2.42.fr.conf

EXPOSE 443
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
