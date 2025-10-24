# docker/nginx/Dockerfile - builds nginx image for webform
FROM nginx:1.26-alpine

# Use your repo nginx config (placed at docker/nginx/nginx.conf)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy application files from the repository root src/ into the nginx html root
COPY ../../src /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
