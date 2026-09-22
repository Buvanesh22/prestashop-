FROM php:8.1-apache

# Install system dependencies and PHP extensions required by PrestaShop
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    default-mysql-client \
    unzip \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        mysqli \
        gd \
        zip \
        intl \
        opcache \
        soap \
        bcmath \
        fileinfo \
        mbstring \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite headers

# Configure PHP settings optimized for Render 512MB RAM limit
RUN echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/prestashop.ini \
    && echo "upload_max_filesize = 32M" >> /usr/local/etc/php/conf.d/prestashop.ini \
    && echo "post_max_size = 32M" >> /usr/local/etc/php/conf.d/prestashop.ini \
    && echo "max_execution_time = 120" >> /usr/local/etc/php/conf.d/prestashop.ini \
    && echo "max_input_vars = 3000" >> /usr/local/etc/php/conf.d/prestashop.ini \
    && echo "date.timezone = UTC" >> /usr/local/etc/php/conf.d/prestashop.ini \
    && echo "opcache.enable = 1" >> /usr/local/etc/php/conf.d/prestashop.ini \
    && echo "opcache.memory_consumption = 64" >> /usr/local/etc/php/conf.d/prestashop.ini \
    && echo "opcache.max_accelerated_files = 8000" >> /usr/local/etc/php/conf.d/prestashop.ini

WORKDIR /var/www/html

# Copy source code
COPY . /var/www/html/

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set directory permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
