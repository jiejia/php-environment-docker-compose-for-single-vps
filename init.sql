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