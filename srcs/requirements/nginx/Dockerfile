FROM debian:bullseye

# Install NGINX and OpenSSL
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
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
    chown -R www-data:www-data /var/www/wordpress

# Remove default NGINX configurations
RUN rm -f /etc/nginx/sites-enabled/default && \
    rm -f /etc/nginx/sites-available/default

# Create symbolic link for our configuration (will be created by entrypoint)
RUN mkdir -p /etc/nginx/sites-enabled

# Expose HTTPS port only (requirement: only port 443)
EXPOSE 443

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/nginx_entrypoint.sh"]
