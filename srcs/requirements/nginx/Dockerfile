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

# Copy SSL certificate generation script
COPY tools/generate_ssl.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate_ssl.sh

# Create necessary directories
RUN mkdir -p /etc/nginx/ssl && \
    mkdir -p /var/www/wordpress && \
    chown -R www-data:www-data /var/www/wordpress

# Generate SSL certificate
RUN /usr/local/bin/generate_ssl.sh

# Expose HTTPS port only
EXPOSE 443

# Start NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]
