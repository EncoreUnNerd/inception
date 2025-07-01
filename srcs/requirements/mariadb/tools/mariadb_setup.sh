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

    # Créer le script d'initialisation SQL
    cat > /tmp/init.sql << EOF
-- Initialisation de la base de données
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Création des utilisateurs avec différents patterns d'hôtes
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'172.%' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%.network_wordpress' IDENTIFIED BY '${DB_PASSWORD}';

-- Attribution des privilèges
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'172.%';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%.network_wordpress';

-- Configuration du mot de passe root
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${DB_ROOT_PASSWORD}');

-- Application des changements
FLUSH PRIVILEGES;
EOF

    echo "Starting MariaDB with initialization script..."
    mysqld_safe --datadir=/var/lib/mysql --bind-address=0.0.0.0 --init-file=/tmp/init.sql &

    # Attendre que l'initialisation soit terminée
    until mysqladmin ping --silent; do
        echo "Waiting for MariaDB initialization..."
        sleep 2
    done

    echo "Database initialization complete!"
    mysqladmin -p${DB_ROOT_PASSWORD} shutdown
    sleep 2

    # Nettoyer le fichier temporaire
    rm -f /tmp/init.sql
else
    echo "Database already initialized"
fi

echo "Starting MariaDB..."
exec mysqld_safe --datadir=/var/lib/mysql --bind-address=0.0.0.0
