FROM php:8.3-fpm-alpine

RUN apk add --no-cache \
    postgresql-dev libzip-dev icu-dev oniguruma-dev \
    && docker-php-ext-install pdo pdo_pgsql zip intl mbstring opcache

WORKDIR /var/www/html

RUN addgroup -g 1000 appuser && adduser -D -u 1000 -G appuser appuser
USER appuser

EXPOSE 9000
CMD ["php-fpm"]
