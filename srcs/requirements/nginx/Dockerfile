FROM debian:12

RUN apt update && apt install -y nginx && apt clean && \
	rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 433
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
