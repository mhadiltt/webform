FROM nginx:1.26-alpine

# Copy custom NGINX config
COPY docker/nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Copy app files
COPY src /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
