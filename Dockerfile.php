FROM serversideup/php:8.5-fpm-alpine

# 安装 mysqli 扩展
RUN install-php-extensions mysqli
