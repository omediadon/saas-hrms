# ./docker/backend/Dockerfile
FROM php:8.3-apache

ARG COMPOSER_ALLOW_SUPERUSER=1

# Set default shell to bash
RUN chsh -s $(which bash)

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        apt-transport-https \
        wget \
        libpng-dev \
        libonig-dev \
        libxml2-dev \
        zip \
        openssl \
		libzip-dev \
		liblz4-dev \
		libzstd-dev \
        unzip \
        tofrodos \
        libfreetype-dev \
        ssl-cert \
        ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd fileinfo \
    && yes | pecl install zstd msgpack igbinary \
    && yes | pecl install xdebug \
    && yes | pecl install redis \
    && docker-php-ext-enable xdebug \
    && docker-php-ext-enable msgpack igbinary zstd \
    && docker-php-ext-enable redis \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && rm -rf /tmp/pear
    
# Set up SSL certificates
COPY ./docker/apache/generate-certs.sh /usr/local/bin/
RUN fromdos /usr/local/bin/generate-certs.sh \
    && chmod +x /usr/local/bin/generate-certs.sh

    
# Enable Apache modules
RUN a2enmod ssl headers rewrite && /etc/init.d/apache2 restart

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Change ownership of our applications
RUN chown -R www-data:www-data /var/www/html

# Expose port 80 and start apache server
EXPOSE 80 8080
CMD ["apache2-foreground"]