FROM debian:bullseye-slim

RUN apt-get update && \
	apt-get install -y mariadb-server && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

RUN mysql_install_db --user=mysql --datadir=/var/lib/mysql

COPY tools/mariadb_setup.sh /tmp/mariadb_setup.sh
RUN chmod +x /tmp/mariadb_setup.sh

EXPOSE 3306

ENTRYPOINT ["/tmp/mariadb_setup.sh"]
