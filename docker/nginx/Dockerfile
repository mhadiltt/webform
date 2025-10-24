# Nginx container only
FROM nginx:alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy web files (optional if using PV)
# COPY ../jenkins-docker-build/src/ /var/www/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
