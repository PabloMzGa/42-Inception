FROM debian:12

# =========================================================
# 1. INSTALL PHP-FPM AND REQUIRED WORDPRESS EXTENSIONS
# =========================================================
# NOTE: Consolidated apt commands into a single layer to minimize image size, including mariadb-client
RUN apt update && apt install -y \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-xml \
    php8.2-zip \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-exif \
    php8.2-fileinfo \
    php8.2-cli \
    php8.2-common \
    mariadb-client \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

# =========================================================
# 1.5. INSTALL WP-CLI (FOR USER AND THEME AUTOMATION)
# =========================================================
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# =========================================================
# 2. DOWNLOAD WORDPRESS CORE
# =========================================================
RUN curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz -C /tmp \
    && rm /tmp/wordpress.tar.gz

# =========================================================
# 3. DEPLOY WORDPRESS AND ENSURE PHP PID DIRECTORY
# =========================================================
# DEBIAN REQUIREMENT: PHP-FPM requires the /run/php directory to exist to store its .pid file.
# If missing from the clean base image, the container will crash upon entrypoint execution.
RUN mkdir -p /var/www/html /run/php \
    && cp -r /tmp/wordpress/* /var/www/html \
    && chown -R www-data:www-data /var/www/html

# =========================================================
# 4. INITIALIZATION SCRIPT DEPLOYMENT
# =========================================================
COPY tools/wp-init.sh /usr/local/bin/wp-init.sh
RUN chmod +x /usr/local/bin/wp-init.sh

# =========================================================
# 5. PHP-FPM POOL CONFIGURATION
# =========================================================
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# =========================================================
# 6. EXPOSE INTERNAL PHP-FPM PORT
# =========================================================
EXPOSE 9000

# =========================================================
# 7. CONTAINER ENTRYPOINT
# =========================================================
ENTRYPOINT ["/usr/local/bin/wp-init.sh"]
