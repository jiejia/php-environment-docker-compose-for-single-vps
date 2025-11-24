#!/bin/bash


docker-compose up -d nginx

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d aripplesong.me -d www.aripplesong.me --email jiejia2009@gmail.com --agree-tos --non-interactive

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d podcast.aripplesong.me --email jiejia2009@gmail.com --agree-tos --non-interactive

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d doc.podcast.aripplesong.me --email jiejia2009@gmail.com --agree-tos --non-interactive

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d cn.podcast.aripplesong.me --email jiejia2009@gmail.com --agree-tos --non-interactive

docker-compose down