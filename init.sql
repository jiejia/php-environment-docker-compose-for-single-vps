CREATE DATABASE IF NOT EXISTS aripplesong;
CREATE USER 'aripplesong'@'localhost' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON aripplesong.* TO 'aripplesong'@'localhost';

CREATE DATABASE IF NOT EXISTS podcast_aripplesong;
CREATE USER 'podcast_aripplesong'@'localhost' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON podcast_aripplesong.* TO 'podcast_aripplesong'@'localhost';

CREATE DATABASE IF NOT EXISTS cn_podcast_aripplesong;
CREATE USER 'cn_podcast_aripplesong'@'localhost' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON cn_podcast_aripplesong.* TO 'cn_podcast_aripplesong'@'localhost';

FLUSH PRIVILEGES;