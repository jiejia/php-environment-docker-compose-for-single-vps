#!/bin/bash

nginx_version=1.28.0
mysql_version=8.4.7
php_version=8.4.15-fpm-alpine3.21
mysql_root_password=123456
tz=Asia/Shanghai
certbot_email=jiejia2009@gmail.com

domains=(
    "aripplesong.me"
    "podcast.aripplesong.me"
    "doc.podcast.aripplesong.me"
    "cn.podcast.aripplesong.me"
)

# create .env file
cat <<EOF > .env
MYSQL_ROOT_PASSWORD=${mysql_root_password}

TZ=${tz}

EOF

# create docker-compose.yml file
cat <<EOF > docker-compose.yml
services:
  # MySQL 数据库服务
  mysql:
    image: mysql:${mysql_version}
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${mysql_root_password}
      TZ: ${tz}
    volumes:
      - ./mysql/my.cnf:/etc/my.cnf
      - ./mysql/data:/var/lib/mysql
      - ./mysql/conf:/etc/mysql/conf.d
      - ./mysql/logs:/var/log/mysql
      - ./mysql/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network
    # command: --default-authentication-plugin=mysql_native_password
    # healthcheck:
    #   test:
    #     [
    #       "CMD",
    #       "mysqladmin",
    #       "ping",
    #       "-h",
    #       "localhost",
    #       "-uroot",
    #       "-p${mysql_root_password}",
    #       "--silent",
    #     ]
    #   timeout: 20s
    #   retries: 10

  # Nginx Web 服务器
  nginx:
    image: nginx:${nginx_version}
    restart: always
    ports:
      - "80:80"
      - "443:443"
    environment:
      TZ: ${tz}
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./sites:/var/www/
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/logs:/var/log/nginx
      - /root/.acme.sh:/root/.acme.sh
      - ./acme:/var/www/acme
    networks:
      - app-network
    depends_on:
      - php-${php_version}
    # command: '/bin/sh -c ''while :; do sleep 6h & wait $${!}; nginx -s reload; done & nginx -g "daemon off;"'''

  # main site PHP-FPM
  php-${php_version}:
    image: php:${php_version}
    restart: always
    environment:
      TZ: ${tz}
    volumes:
      - ./sites:/var/www
      - ./php/${php_version}/php.ini:/usr/local/etc/php/php.ini
    networks:
      - app-network
    depends_on:
      - mysql

networks:
  app-network:
    driver: bridge
EOF


# mysql init script
mkdir ./mysql
mkdir ./mysql/data
mkdir ./mysql/conf
mkdir ./mysql/logs

cat <<EOF > ./mysql/init.sql
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

docker run --rm --entrypoint=cat  mysql:${mysql_version} /etc/my.cnf > ./mysql/my.cnf

# nginx init script
mkdir ./nginx
mkdir ./nginx/conf.d
mkdir ./nginx/logs
docker run --rm --entrypoint=cat nginx:${nginx_version} /etc/nginx/nginx.conf > ./nginx/nginx.conf


# php init script
mkdir -p ./php/${php_version}/
docker run --rm --entrypoint=cat php:${php_version} /usr/local/etc/php/php.ini-production > ./php/${php_version}/php.ini

# create sites init script
mkdir ./sites/

for domain in "${domains[@]}"; do
    mkdir ./sites/$domain
    
    # 判断是否为顶级域名（只有一个点）
    dot_count=$(echo "$domain" | tr -cd '.' | wc -c)
    if [ "$dot_count" -eq 1 ]; then
        is_apex_domain=true
        www_domain="www.$domain"
    else
        is_apex_domain=false
        www_domain=""
    fi

cat <<EOF > ./nginx/conf.d/$domain.conf
# nginx/conf.d/$domain.conf

server {
    listen 80;
    server_name $domain${is_apex_domain:+ $www_domain};
    
    # ACME 挑战目录
    location /.well-known/acme-challenge/ {
        root /var/www/acme;
    }

    # 其他请求重定向到 HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

EOF

# 如果是顶级域名，添加 www 到非 www 的 HTTPS 跳转
if [ "$is_apex_domain" = true ]; then
cat <<EOF >> ./nginx/conf.d/$domain.conf
# www 到非 www 的重定向
server {
    listen 443 ssl;
    http2 on;
    server_name $www_domain;
    
    # SSL 证书配置（使用主域名的证书）
    ssl_certificate /root/.acme.sh/${domain}_ecc/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/${domain}_ecc/$domain.key;
    
    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # 301 永久重定向到非 www 版本
    return 301 https://$domain\$request_uri;
}

EOF
fi

cat <<EOF >> ./nginx/conf.d/$domain.conf
server {
    listen 443 ssl;
    http2 on;
    server_name $domain;
    
    root /var/www/$domain;
    index index.php index.html index.htm;
    
    # SSL 证书配置
    ssl_certificate /root/.acme.sh/${domain}_ecc/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/${domain}_ecc/$domain.key;
    
    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass php-${php_version}:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
done


# acme.sh init script
mkdir ./acme

# generate temporary ssl certificate
for domain in "${domains[@]}"; do
    mkdir -p ~/.acme.sh/${domain}_ecc
    openssl req -x509 -nodes -days 3650 \
        -subj "/CN=$domain" \
        -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
        -keyout ~/.acme.sh/${domain}_ecc/$domain.key \
        -out ~/.acme.sh/${domain}_ecc/fullchain.cer
done