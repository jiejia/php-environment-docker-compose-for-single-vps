#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载 .env 文件
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

docker-compose up -d nginx

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d aripplesong.me -d www.aripplesong.me --email jiejia2009@gmail.com --agree-tos --non-interactive

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d podcast.aripplesong.me --email jiejia2009@gmail.com --agree-tos --non-interactive

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d doc.podcast.aripplesong.me --email jiejia2009@gmail.com --agree-tos --non-interactive

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d cn.podcast.aripplesong.me --email jiejia2009@gmail.com --agree-tos --non-interactive

docker-compose down