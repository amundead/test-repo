# Use the Windows Server Core 2019 as the base image
FROM mcr.microsoft.com/windows/servercore:ltsc2019

# Install IIS
RUN dism.exe /online /enable-feature /all /featurename:IIS-WebServer /NoRestart

# Install PHP
RUN powershell -Command \
    Invoke-WebRequest -Uri "https://windows.php.net/downloads/releases/php-8.2.0-Win32-vs16-x64.zip" -OutFile "php.zip" ; \
    Expand-Archive -Path php.zip -DestinationPath C:\php ; \
    Remove-Item -Force php.zip ; \
    setx PATH "%PATH%;C:\php"

# Configure IIS to handle PHP
RUN powershell -Command \
    Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/handlers' -name '.' -value @{name='PHP_via_FastCGI'; path='*'; verb='GET,HEAD,POST'; modules='FastCgiModule'; scriptProcessor='C:\php\php-cgi.exe'; resourceType='Either'} ; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/fastCgi' -name '.' -value @{fullPath='C:\php\php-cgi.exe'}

# Add Hello World PHP script
RUN powershell -Command \
    New-Item -Path "C:\inetpub\wwwroot\index.php" -ItemType "File" -Value "<?php echo 'Hello, World!'; ?>"

# Expose port 80
EXPOSE 80

# Start IIS
CMD ["powershell", "-Command", "Start-Service W3SVC; while ($true) { Start-Sleep -Seconds 3600; }"]
