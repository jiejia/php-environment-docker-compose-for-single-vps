#!/bin/bash

# create .env file
cat <<'EOF' > .env
MYSQL_ROOT_PASSWORD=123456

TZ=Asia/Shanghai

CERTBOT_EMAIL=jiejia2009@gmail.com
EOF

# certbot apply script
cat <<'EOF' > certbot_apply.sh
# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载 .env 文件
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

docker-compose up -d nginx

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d aripplesong.me -d www.aripplesong.me --email ${CERTBOT_EMAIL} --agree-tos --non-interactive

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d podcast.aripplesong.me --email ${CERTBOT_EMAIL} --agree-tos --non-interactive

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d doc.podcast.aripplesong.me --email ${CERTBOT_EMAIL} --agree-tos --non-interactive

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d cn.podcast.aripplesong.me --email ${CERTBOT_EMAIL} --agree-tos --non-interactive

docker-compose down
EOF

# certbot renew script
cat <<'EOF' > certbot_renew.sh
docker-compose run --rm certbot renew

docker-compose exec nginx nginx -s reload
EOF

# create docker-compose.yml file
cat <<'EOF' > docker-compose.yml
services:

  # MySQL 数据库服务
  mysql:
    image: mysql:8.4.7
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      TZ: ${TZ:-Asia/Shanghai}
    volumes:
      - ./mysql/my.cnf:/etc/my.cnf
      - ./mysql/data:/var/lib/mysql
      - ./mysql/conf:/etc/mysql/conf.d
      - ./mysql/logs:/var/log/mysql
      - ./mysql/init.sql:/docker-entrypoint-initdb.d/init.sql

    networks:
      - app-network
    command: --default-authentication-plugin=mysql_native_password
    healthcheck:
      test:
        [
          "CMD",
          "mysqladmin",
          "ping",
          "-h",
          "localhost",
          "-uroot",
          "-p${MYSQL_ROOT_PASSWORD}",
          "--silent",
        ]
      timeout: 20s
      retries: 10

  # Nginx Web 服务器
  nginx:
    image: nginx:1.28.0
    restart: always
    ports:
      - "80:80"
      - "443:443"
    environment:
      TZ: ${TZ:-Asia/Shanghai}
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./sites/cn.podcast.aripplesong.me/public:/var/www/cn.podcast.aripplesong.me
      - ./sites/doc.podcast.aripplesong.me/public:/var/www/doc.podcast.aripplesong.me
      - ./sites/podcast.aripplesong.me/public:/var/www/podcast.aripplesong.me
      - ./sites/aripplesong.me/public:/var/www/aripplesong.me$
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/logs:/var/log/nginx
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    networks:
      - app-network
    depends_on:
      - php-cn-podcast
      - php-doc-podcast
      - php-podcast
    command: "/bin/sh -c 'while :; do sleep 6h & wait $${!}; nginx -s reload; done & nginx -g \"daemon off;\"'"     

   # Certbot SSL 证书管理
  certbot:
    image: certbot/certbot:latest
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    networks:
      - app-network   
    profiles:
      - certbot
    depends_on:
      - nginx
    command: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"

  # main site PHP-FPM
  php:
    image: php:8.4.15-fpm-alpine3.21
    restart: always
    environment:
      TZ: ${TZ:-Asia/Shanghai}
    volumes:
      - ./sites/aripplesong.me/public:/var/www/aripplesong.me
      - ./sites/aripplesong.me/php.ini:/usr/local/etc/php/php.ini
    networks:
      - app-network
    depends_on:
      mysql:
        condition: service_healthy     

  # CN Podcast PHP-FPM
  php-podcast:
    image: php:8.4.15-fpm-alpine3.21
    restart: always
    environment:
      TZ: ${TZ:-Asia/Shanghai}
    volumes:
      - ./sites/podcast.aripplesong.me/public:/var/www/podcast.aripplesong.me
      - ./sites/podcast.aripplesong.me/php.ini:/usr/local/etc/php/php.ini
    networks:
      - app-network
    depends_on:
      mysql:
        condition: service_healthy     

  # CN Podcast PHP-FPM
  php-cn-podcast:
    image: php:8.4.15-fpm-alpine3.21
    restart: always
    environment:
      TZ: ${TZ:-Asia/Shanghai}
    volumes:
      - ./sites/cn.podcast.aripplesong.me/public:/var/www/cn.podcast.aripplesong.me
      - ./sites/cn.podcast.aripplesong.me/php.ini:/usr/local/etc/php/php.ini
    networks:
      - app-network
    depends_on:
      mysql:
        condition: service_healthy     

  # doc Podcast PHP-FPM
  php-doc-podcast:
    image: php:8.4.15-fpm-alpine3.21
    restart: always
    environment:
      TZ: ${TZ:-Asia/Shanghai}
    volumes:
      - ./sites/doc.podcast.aripplesong.me/public:/var/www/doc.podcast.aripplesong.me
      - ./sites/doc.podcast.aripplesong.me/php.ini:/usr/local/etc/php/php.ini
    networks:
      - app-network
    depends_on:
      mysql:
        condition: service_healthy

networks:
  app-network:
    driver: bridge

EOF


# mysql init script
mkdir ./mysql
mkdir ./mysql/data
mkdir ./mysql/conf
mkdir ./mysql/logs

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

docker-compose run --rm  mysql cat /etc/my.cnf > ./mysql/my.cnf

# nginx init script
mkdir ./nginx
mkdir ./nginx/conf.d
mkdir ./nginx/logs
mkdir -p ./sites/cn.podcast.aripplesong.me/public    
mkdir -p ./sites/doc.podcast.aripplesong.me/public
mkdir -p ./sites/podcast.aripplesong.me/public
mkdir -p ./sites/aripplesong.me/public

docker-compose run --rm nginx cat /etc/nginx/nginx.conf > ./nginx/nginx.conf


# php init script
docker-compose run --rm php-cn-podcast cat /usr/local/etc/php/php.ini-production > ./sites/cn.podcast.aripplesong.me/php.ini
docker-compose run --rm php-doc-podcast cat /usr/local/etc/php/php.ini-production > ./sites/doc.podcast.aripplesong.me/php.ini
docker-compose run --rm php-podcast cat /usr/local/etc/php/php.ini-production > ./sites/podcast.aripplesong.me/php.ini
docker-compose run --rm php cat /usr/local/etc/php/php.ini-production > ./sites/aripplesong.me/php.ini


# certbot init script
mkdir -p ./certbot/conf
mkdir -p ./certbot/www



