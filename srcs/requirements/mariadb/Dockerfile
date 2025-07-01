FROM debian:bullseye-slim

RUN apt-get update && \
	apt-get install -y mariadb-server && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# Créer les répertoires nécessaires
RUN mkdir -p /run/mysqld && \
	chown mysql:mysql /run/mysqld

# Copier la configuration personnalisée
COPY tools/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY tools/mariadb_setup.sh /tmp/mariadb_setup.sh
RUN chmod +x /tmp/mariadb_setup.sh

EXPOSE 3306

ENTRYPOINT ["/tmp/mariadb_setup.sh"]
