# DOCKER-VERSION        1.3.2

FROM composer:latest as composer
FROM php:7.3-cli-alpine

WORKDIR /var/www

ARG SWOOLEVERSION
ENV SWOOLEPACKAGE swoole-$SWOOLEVERSION.tgz

# System dependencies
RUN apk update && \
    apk add --no-cache autoconf g++ gcc git libbz2 libxslt make nghttp2-dev procps zlib-dev && \
    docker-php-ext-install -j$(nproc) sockets

# Compile and install Swoole
RUN mkdir -p /tmp/swoole && \
    cd /tmp/swoole && \
    curl -s -o swoole.tgz https://pecl.php.net/get/$SWOOLEPACKAGE && \
    tar xzvf swoole.tgz --strip-components=1 && \
    phpize && \
    ./configure --enable-http2 && \
    make && \
    make install && \
    cd /tmp && \
    rm -Rf swoole

# PHP configuration
COPY swoole.ini /usr/local/etc/php/conf.d/000-swoole.ini

# Install composer
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

# Install Prestissimo composer plugin
RUN composer global require hirak/prestissimo

# Project files
COPY index.php /var/www/public/
COPY entrypoint /usr/local/bin/

EXPOSE 9000
ENTRYPOINT ["entrypoint"]
