FROM debian:12

RUN apt update && apt install -y nginx && apt clean && \
	rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]
