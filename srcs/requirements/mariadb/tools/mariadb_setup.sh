#!/bin/bash

# Lire les secrets Docker
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# Créer le répertoire pour mysqld si nécessaire
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

echo "=== MariaDB Setup ==="
echo "MYSQL_DATABASE: $MYSQL_DATABASE"
echo "MYSQL_USER: $MYSQL_USER"

# Vérifier si la base est déjà initialisée
if [ ! -f "/var/lib/mysql/mysql/user.MYD" ]; then
    echo "Initializing database..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "Starting MariaDB temporarily for setup..."
    mysqld_safe --datadir=/var/lib/mysql --bind-address=0.0.0.0 --skip-grant-tables &

    # Attendre que MariaDB soit prêt
    until mysqladmin ping --silent; do
        echo "Waiting for MariaDB to start..."
        sleep 2
    done

    echo "Setting up database and users..."

    # Créer un script SQL temporaire
    cat > /tmp/setup.sql << EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER '${MYSQL_USER}'@'172.%' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER '${MYSQL_USER}'@'%.network_wordpress' IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'172.%';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%.network_wordpress';

ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # Exécuter le script
    mysql < /tmp/setup.sql

    echo "Database setup complete!"
    mysqladmin shutdown
    sleep 2
else
    echo "Database already initialized"
fi

echo "Starting MariaDB..."
exec mysqld_safe --datadir=/var/lib/mysql --bind-address=0.0.0.0
