# Use PHP-FPM base image (no Apache)
FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www/html

# Copy your application code into the container
COPY . /var/www/html

# Set proper file permissions
RUN chown -R www-data:www-data /var/www/html

# Expose PHP-FPM port
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]
