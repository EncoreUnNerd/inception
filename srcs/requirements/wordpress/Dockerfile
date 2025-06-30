FROM debian:bullseye

RUN apt-get update && \
	apt-get install -y \
	php7.4-fpm \
	php7.4-mysql \
	php7.4-curl \
	php7.4-gd \
	php7.4-intl \
	php7.4-mbstring \
	php7.4-soap \
	php7.4-xml \
	php7.4-xmlrpc \
	php7.4-zip \
	php7.4-cli \
	mariadb-client \
	wget \
	curl && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html && \
	chown -R www-data:www-data /var/www/html && \
	chmod -R 755 /var/www/html


# Installation de WP-CLI avec le lien fonctionnel
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp

# Télécharger WordPress
RUN wp core download --path=/var/www/html --allow-root

# Configuration PHP-FPM
RUN sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 0.0.0.0:9000/' /etc/php/7.4/fpm/pool.d/www.conf

COPY tools/wordpress_setup.sh /tmp/wordpress_setup.sh
RUN chmod +x /tmp/wordpress_setup.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/tmp/wordpress_setup.sh"]
