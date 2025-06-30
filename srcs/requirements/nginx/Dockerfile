FROM debian:bullseye-slim

RUN apt-get update && \
	apt-get install -y nginx openssl && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

COPY ./nginx.conf /etc/nginx/sites-available/my-secure-site

RUN rm /etc/nginx/sites-enabled/default && \
	ln -s /etc/nginx/sites-available/my-secure-site /etc/nginx/sites-enabled/

RUN mkdir /etc/nginx/certs

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/certs/nginx.key \
	-out /etc/nginx/certs/nginx.crt \
	-subj "/C=FR/ST=Paris/L=Paris/O=Inception/CN=mhenin.42.fr"

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
