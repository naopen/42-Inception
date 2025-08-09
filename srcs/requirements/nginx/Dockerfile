FROM debian:bullseye

# Install NGINX and OpenSSL
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Copy NGINX configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/default.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Copy scripts
COPY tools/generate_ssl.sh /usr/local/bin/
COPY tools/nginx_entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate_ssl.sh /usr/local/bin/nginx_entrypoint.sh

# Create necessary directories
RUN mkdir -p /etc/nginx/ssl && \
    mkdir -p /var/www/wordpress && \
    chown -R www-data:www-data /var/www/wordpress

# Remove default NGINX site
RUN rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# Create the symbolic link for our configuration
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Expose HTTPS port only (requirement: only port 443)
EXPOSE 443

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/nginx_entrypoint.sh"]
