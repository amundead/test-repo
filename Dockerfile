# Use the Windows Server Core 2019 as the base image
FROM mcr.microsoft.com/windows/servercore:ltsc2019

# Install IIS and CGI
RUN dism.exe /online /enable-feature /all /featurename:IIS-WebServer /NoRestart && \
    dism.exe /online /enable-feature /all /featurename:IIS-CGI /NoRestart && \
    dism.exe /online /enable-feature /all /featurename:IIS-WebServerManagementTools /NoRestart

# Install PHP
RUN powershell -Command \
    Invoke-WebRequest -Uri "https://windows.php.net/downloads/releases/php-8.4.1-Win32-vs17-x64.zip" -OutFile "php.zip"; \
    Expand-Archive -Path php.zip -DestinationPath C:\php; \
    Remove-Item -Force php.zip

# Set PHP path for current session and globally
RUN setx /M PATH "%PATH%;C:\php" && \
    powershell -Command $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)

# Configure FastCGI for PHP
RUN powershell -Command \
    Import-Module WebAdministration; \
    if (Get-Command Remove-WebConfiguration -ErrorAction SilentlyContinue) { \
        Remove-WebConfiguration -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/fastCgi/application' -value @{fullPath='C:\php\php-cgi.exe'} -ErrorAction SilentlyContinue; \
    } else { \
        Write-Host 'Remove-WebConfiguration cmdlet not found'; \
    } \
    Add-WebConfiguration -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/fastCgi/application' -value @{fullPath='C:\php\php-cgi.exe'; instanceMaxRequests=200; activityTimeout=600; requestTimeout=600}

# Configure PHP handler mapping
RUN powershell -Command \
    Import-Module WebAdministration; \
    Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/handlers' -name '.' -value @{name='PHP_via_FastCGI'; path='*.php'; verb='*'; modules='FastCgiModule'; scriptProcessor='C:\php\php-cgi.exe'; resourceType='Either'}

# Ensure PHP CGI has correct permissions
RUN icacls "C:\php\php-cgi.exe" /grant "IIS_IUSRS:(RX)"

# Verify PHP CGI binary exists
RUN powershell -Command \
    if (!(Test-Path -Path 'C:\php\php-cgi.exe')) { throw 'PHP CGI binary not found at C:\php\php-cgi.exe'; }

# Enable detailed IIS errors
RUN powershell -Command \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/httpErrors' -name 'errorMode' -value 'Detailed'

# Add Hello World PHP script
RUN powershell -Command \
    "[System.IO.File]::WriteAllText('C:\\inetpub\\wwwroot\\index.php', '<?php phpinfo(); ?>')"

# Expose port 80
EXPOSE 80

# Start IIS
CMD ["powershell", "-Command", "Start-Service W3SVC; while ($true) { Start-Sleep -Seconds 3600; }"]
