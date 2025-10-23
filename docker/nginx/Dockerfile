FROM nginx:1.26-alpine
# when context = repository root (.) paths must be repo-root-relative
COPY docker/nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY src /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
