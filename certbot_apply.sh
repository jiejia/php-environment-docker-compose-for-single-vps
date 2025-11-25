#!/bin/bash


docker-compose up 

rm -rf ./certbot/conf/live/*

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d aripplesong.me -d www.aripplesong.me --email ${certbot_email} --agree-tos --non-interactive

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d podcast.aripplesong.me --email ${certbot_email} --agree-tos --non-interactive

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d doc.podcast.aripplesong.me --email ${certbot_email} --agree-tos --non-interactive

docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d cn.podcast.aripplesong.me --email ${certbot_email} --agree-tos --non-interactive

docker-compose exec nginx nginx -s reload

docker-compose down