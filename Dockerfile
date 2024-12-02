# Dockerfile
FROM mcr.microsoft.com/windows/servercore:ltsc2019

# Set environment variables for installation paths
ENV NGINX_VERSION=1.27.3
ENV PHP_VERSION=8.4.1

# Install tools, download, and set up Nginx
RUN powershell -Command \
    "$nginxVersion = '${NGINX_VERSION}'; \
    Invoke-WebRequest -Uri ('https://nginx.org/download/nginx-' + $nginxVersion + '.zip') -OutFile C:\\nginx.zip; \
    Expand-Archive -Path C:\\nginx.zip -DestinationPath C:\\; \
    Remove-Item -Force C:\\nginx.zip; \
    Rename-Item -Path ('C:\\nginx-' + $nginxVersion) -NewName C:\\nginx"

# Install tools, download, and set up PHP
RUN powershell -Command \
    "$phpVersion = '${PHP_VERSION}'; \
    Invoke-WebRequest -Uri ('https://windows.php.net/downloads/releases/php-' + $phpVersion + '-Win32-vs17-x64.zip') -OutFile C:\\php.zip; \
    Expand-Archive -Path C:\\php.zip -DestinationPath C:\\php; \
    Remove-Item -Force C:\\php.zip"

# Set up environment variables for PHP
ENV PATH="C:\\php;${PATH}"

# Copy nginx.conf
COPY nginx.conf C:\\nginx\\conf\\nginx.conf

# Copy PHP script
COPY hello-world.php C:\\nginx\\html\\hello-world.php

# Expose port 80
EXPOSE 80

# Command to start Nginx
CMD ["C:\\nginx\\nginx.exe"]
