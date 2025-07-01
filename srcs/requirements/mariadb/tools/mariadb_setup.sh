#!/bin/bash

# Lire les secrets Docker
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# Créer le répertoire pour mysqld si nécessaire
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing database..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "Starting MariaDB temporarily for setup..."
    mysqld_safe --datadir=/var/lib/mysql &

    # Attendre que MariaDB soit prêt
    until mysqladmin ping --silent; do
        echo "Waiting for MariaDB to start..."
        sleep 2
    done

    echo "Setting up database and users..."
    mysql -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;"
    mysql -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';"
    mysql -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';"
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';"
    mysql -e "FLUSH PRIVILEGES;"

    echo "Shutting down temporary MariaDB..."
    mysqladmin shutdown

    echo "Database setup complete!"
fi

echo "Starting MariaDB..."
exec mysqld_safe --datadir=/var/lib/mysql
