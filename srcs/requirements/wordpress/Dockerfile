FROM debian:bullseye

# Install PHP-FPM and required packages
RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-mysqli \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    wget \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Copy PHP-FPM configuration
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Copy WordPress setup script
COPY tools/wp_setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp_setup.sh

# Create necessary directories
RUN mkdir -p /var/www/wordpress && \
    chown -R www-data:www-data /var/www/wordpress && \
    mkdir -p /run/php

# Set working directory
WORKDIR /var/www/wordpress

# Expose PHP-FPM port
EXPOSE 9000

# Run the setup script
ENTRYPOINT ["/usr/local/bin/wp_setup.sh"]

# Start PHP-FPM
CMD ["php-fpm7.4", "-F"]
