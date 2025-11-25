#!/bin/bash

export ACME_HOME=~/.acme.sh
alias acme.sh=~/.acme.sh/acme.sh

acme.sh --issue -d aripplesong.me -d www.aripplesong.me --webroot ./acme --force --ecc
acme.sh --issue -d podcast.aripplesong.me --webroot ./acme --force --ecc
acme.sh --issue -d doc.podcast.aripplesong.me --webroot ./acme --force --ecc
acme.sh --issue -d cn.podcast.aripplesong.me --webroot ./acme --force --ecc



acme.sh --renew -d aripplesong.me -d www.aripplesong.me --force --ecc
acme.sh --renew -d podcast.aripplesong.me --force --ecc
acme.sh --renew -d doc.podcast.aripplesong.me --force --ecc
acme.sh --renew -d cn.podcast.aripplesong.me --force --ecc


docker-compose exec nginx nginx -s reload