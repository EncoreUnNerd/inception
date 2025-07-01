#!/bin/bash

# Lire les secrets Docker
DB_PASSWORD=$(cat /run/secrets/db_password)
CREDENTIALS=$(cat /run/secrets/credentials)

# Extraire login et password depuis credentials (format: login:password)
WP_ADMIN_USER=$(echo $CREDENTIALS | cut -d':' -f1)
WP_ADMIN_PASSWORD=$(echo $CREDENTIALS | cut -d':' -f2)

# S'assurer que le répertoire PHP existe
mkdir -p /run/php
chown www-data:www-data /run/php

echo "Waiting for MariaDB to be ready..."
# Attendre que MariaDB soit prêt avec un timeout
TIMEOUT=60
COUNTER=0
until mysql -h$WORDPRESS_DB_HOST -u$DB_USER -p$DB_PASSWORD -e "SELECT 1" >/dev/null 2>&1; do
	if [ $COUNTER -eq $TIMEOUT ]; then
		echo "ERROR: Timeout waiting for MariaDB"
		exit 1
	fi
	echo "Waiting for MariaDB... ($COUNTER/$TIMEOUT)"
    sleep 2
    COUNTER=$((COUNTER + 1))
done
echo "MariaDB is ready!"

if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Configuring WordPress..."
    wp core config --path=/var/www/html \
        --dbname=$DB_NAME \
        --dbuser=$DB_USER \
        --dbpass=$DB_PASSWORD \
        --dbhost=$WORDPRESS_DB_HOST \
        --allow-root

    echo "Installing WordPress..."
    wp core install --path=/var/www/html \
        --url=$DOMAIN_NAME \
        --title="Inception Project" \
        --admin_user=$WP_ADMIN_USER \
        --admin_password=$WP_ADMIN_PASSWORD \
        --admin_email=$WORDPRESS_ADMIN_EMAIL \
        --skip-email \
        --allow-root

    echo "Creating additional user..."
    wp user create $WORDPRESS_USER $WORDPRESS_USER_EMAIL \
        --user_pass=$WORDPRESS_USER_PASSWORD \
        --role=author \
        --allow-root
fi

echo "Setting permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "Starting PHP-FPM..."
exec php-fpm7.4 -F
