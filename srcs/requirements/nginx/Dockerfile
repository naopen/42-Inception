FROM debian:bullseye

# Install NGINX, OpenSSL and debugging tools
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    procps \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Copy NGINX base configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy entrypoint script
COPY tools/nginx_entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/nginx_entrypoint.sh

# Create necessary directories
RUN mkdir -p /etc/nginx/ssl && \
    mkdir -p /var/www/wordpress && \
    mkdir -p /var/log/nginx && \
    mkdir -p /run/nginx && \
    mkdir -p /etc/nginx/sites-available && \
    mkdir -p /etc/nginx/sites-enabled && \
    chown -R www-data:www-data /var/www/wordpress

# Remove any default configurations
RUN rm -f /etc/nginx/sites-enabled/* && \
    rm -f /etc/nginx/sites-available/* && \
    rm -f /etc/nginx/conf.d/*

# Expose HTTPS port only (requirement: only port 443)
EXPOSE 443

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/nginx_entrypoint.sh"]
