#!/bin/bash

# create .env file
cat <<'EOF' > .env
TZ=Asia/Shanghai

MYSQL_IMAGE_VERSION=8.4.7
MYSQL_ROOT_PASSWORD=123456

NGINX_IMAGE_VERSION=1.28.0
EOF

# mysql init script
mkdir -p ./mysql
mkdir ./mysql/data
mkdir ./mysql/conf
mkdir ./mysql/logs
mkdir ./mysql/init.sql

cat <<'EOF' > ./mysql/init.sql
CREATE DATABASE IF NOT EXISTS aripplesong;
CREATE USER 'aripplesong'@'%' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON aripplesong.* TO 'aripplesong'@'%';

CREATE DATABASE IF NOT EXISTS podcast_aripplesong;
CREATE USER 'podcast_aripplesong'@'%' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON podcast_aripplesong.* TO 'podcast_aripplesong'@'%';

CREATE DATABASE IF NOT EXISTS cn_podcast_aripplesong;
CREATE USER 'cn_podcast_aripplesong'@'%' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON cn_podcast_aripplesong.* TO 'cn_podcast_aripplesong'@'%';

FLUSH PRIVILEGES;
EOF

docker run --rm --entrypoint=cat mysql:8.4.7 /etc/my.cnf > ./mysql/my.cnf


# nginx init script
mkdir -p ./nginx
mkdir ./nginx/conf.d
mkdir ./nginx/sites
mkdir -p ./sites/cn.podcast.aripplesong.me/public    
mkdir -p ./sites/doc.podcast.aripplesong.me/public
mkdir -p ./sites/podcast.aripplesong.me/public
mkdir ./nginx/certbot
mkdir ./nginx/certbot/conf
mkdir ./nginx/certbot/www

docker run --rm --entrypoint=cat nginx:1.28.0 /etc/nginx/nginx.conf > ./nginx/nginx.conf


# php init script
docker run --rm php:8.4.15-fpm-alpine3.21 cat /usr/local/etc/php/php.ini-production > ./sites/cn.podcast.aripplesong.me/php.ini
docker run --rm php:8.4.15-fpm-alpine3.21 cat /usr/local/etc/php/php.ini-production > ./sites/doc.podcast.aripplesong.me/php.ini
docker run --rm php:8.4.15-fpm-alpine3.21 cat /usr/local/etc/php/php.ini-production > ./sites/podcast.aripplesong.me/php.ini