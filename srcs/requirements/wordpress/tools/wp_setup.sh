#!/bin/bash

# Wait for MariaDB to be ready
echo "Waiting for MariaDB..."
while ! mysqladmin ping -h"mariadb" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    sleep 1
done
echo "MariaDB is ready!"

# Download WordPress if not exists
if [ ! -f /var/www/wordpress/wp-config.php ]; then
    echo "Downloading WordPress..."
    
    # Download WordPress
    wp core download --allow-root --path=/var/www/wordpress
    
    # Create wp-config.php
    wp config create \
        --dbname="${WP_DB_NAME}" \
        --dbuser="${WP_DB_USER}" \
        --dbpass="${WP_DB_PASSWORD}" \
        --dbhost="${WP_DB_HOST}" \
        --allow-root \
        --path=/var/www/wordpress
    
    # Install WordPress
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root \
        --path=/var/www/wordpress
    
    # Create additional user
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root \
        --path=/var/www/wordpress
    
    # Set correct permissions
    chown -R www-data:www-data /var/www/wordpress
    
    echo "WordPress installation complete!"
else
    echo "WordPress already installed, skipping..."
fi

# Execute the CMD (php-fpm)
exec "$@"
