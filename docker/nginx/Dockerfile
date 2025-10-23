FROM nginx:1.26-alpine

COPY docker/nginx/nginx.conf /etc/nginx/conf.d/default.conf

COPY src /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
