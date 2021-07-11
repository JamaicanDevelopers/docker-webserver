# Alpine Image for Nginx and PHP

# NGINX x ALPINE.
FROM nginx:stable-alpine

# MAINTAINER OF THE PACKAGE.
LABEL maintainer="Oshane Bailey <b4.oshany@gmail.com>"

# INSTALL SOME SYSTEM PACKAGES.
RUN apk --update --no-cache add ca-certificates \
    bash \
    supervisor \
    git


# http://dl-cdn.alpinelinux.org/ has been deprecated
# See https://github.com/codecasts/php-alpine/issues/131
# Use https://packages.whatwedo.ch/php-alpine/{ALPINE_VERSION}/php-{PHP_VERSION} instead
# trust this project public key to trust the packages.
ADD https://packages.whatwedo.ch/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

# CONFIGURE ALPINE REPOSITORIES AND PHP BUILD DIR.
ARG PHP_VERSION=7.4
ARG ALPINE_VERSION=3.12
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community" >> /etc/apk/repositories && \
    echo "https://packages.whatwedo.ch/php-alpine/v${ALPINE_VERSION}/php-${PHP_VERSION}" >> /etc/apk/repositories

# INSTALL PHP AND SOME EXTENSIONS. SEE: https://github.com/codecasts/php-alpine
RUN apk add --no-cache --update php-fpm \
    zip \
    unzip \
    php \
    php-openssl \
    php-pdo \
    php-pdo_mysql \
    php-mbstring \
    php-exif \
    php-phar \
    php-session \
    php-dom \
    php-ctype \
    php-zlib \
    php-json \
    php-iconv \
    php-gd \
    php-curl \
    php-zip \
    php-xml \
    php-intl \
    php-xmlreader && \
    ln -s /usr/bin/php7 /usr/bin/php

RUN apk add npm nodejs --update --repository="http://dl-cdn.alpinelinux.org/alpine/v3.13/main/"

# CONFIGURE WEB SERVER.
RUN mkdir -p /var/www && \
    mkdir -p /run/php && \
    mkdir -p /run/nginx && \
    mkdir -p /var/log/supervisor && \
    mkdir -p /etc/nginx/sites-enabled && \
    mkdir -p /etc/nginx/sites-available && \
    rm /etc/nginx/nginx.conf && \
    rm /etc/php7/php-fpm.d/www.conf && \
    rm /etc/php7/php.ini

# INSTALL COMPOSER.
COPY --from=composer:1.10 /usr/bin/composer /usr/bin/composer

RUN addgroup -g 1000 laravel && adduser --uid 1000 -G laravel -g laravel -s /bin/bash -D laravel
RUN chown laravel:laravel /var/www/

# ADD START SCRIPT, SUPERVISOR CONFIG, NGINX CONFIG AND RUN SCRIPTS.
ADD start.sh /start.sh
ADD config/supervisor/supervisord.conf /etc/supervisord.conf
ADD config/nginx/nginx.conf /etc/nginx/nginx.conf
ADD config/nginx/site.conf /etc/nginx/sites-available/default.conf
ADD config/php/php.ini /etc/php7/php.ini
ADD config/php-fpm/www.conf /etc/php7/php-fpm.d/www.conf
RUN chmod 755 /start.sh

# EXPOSE PORTS!
ARG NGINX_HTTP_PORT=80
ARG NGINX_HTTPS_PORT=443
EXPOSE ${NGINX_HTTPS_PORT} ${NGINX_HTTP_PORT}

# SET THE WORK DIRECTORY.
WORKDIR /var/www

# KICKSTART!
CMD ["/start.sh"]
