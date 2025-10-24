# Dockerfile for PHP-FPM
FROM php:8.2-fpm

WORKDIR /var/www/html

# Copy the PHP app files from the correct folder
COPY jenkins-docker-build/src/ .

# Set permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 9000
CMD ["php-fpm"]

