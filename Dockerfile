FROM php:8.2-fpm

WORKDIR /var/www/html

# Copy your app
COPY ../jenkins-docker-build/src/ .

# Set permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 9000

CMD ["php-fpm"]
