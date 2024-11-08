# Start with the official Nginx image from Docker Hub
FROM nginx:latest

# Copy static website files into the default web root
# (default location for Nginx is /usr/share/nginx/html)
COPY ./html /usr/share/nginx/html

# Expose port 80 to allow access to the web server
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]