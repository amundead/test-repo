# Use the Windows Server Core IIS image
FROM mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2019

# Install PHP and VC++ Redistributable
RUN powershell.exe -Command `
    Invoke-WebRequest -Uri "https://windows.php.net/downloads/releases/php-8.4.1-nts-Win32-vs17-x64.zip" -OutFile "C:\\php.zip"; `
    Expand-Archive -Path "C:\\php.zip" -DestinationPath "C:\\php"; `
    Remove-Item -Force "C:\\php.zip"; `
    Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "C:\\vc_redist.x64.exe"; `
    Start-Process -FilePath "C:\\vc_redist.x64.exe" -ArgumentList '/install', '/quiet', '/norestart' -Wait; `
    Remove-Item -Force "C:\\vc_redist.x64.exe"; `
    [System.Environment]::SetEnvironmentVariable('PATH', $env:PATH + ';C:\\php', [System.EnvironmentVariableTarget]::Machine)

# Enable IIS CGI feature
RUN dism.exe /online /enable-feature /all /featureName:IIS-CGI

# Configure IIS for PHP
RUN powershell.exe -Command `
    Import-Module IISAdministration; `
    New-IISHandlerMapping -Name "PHP" -Path "*.php" -Verb "*" `
        -ScriptProcessor "C:\\php\\php-cgi.exe" -ResourceType File -PreCondition "bitness64"; `
    New-Item -Path "IIS:\\AppPools\\DefaultAppPool" -Name "Enable32BitAppOnWin64" -Value "False"

# Optional: Add a starter page
RUN powershell.exe -Command "'<?php phpinfo(); ?>' | Out-File C:\\inetpub\\wwwroot\\index.php -Encoding UTF8"

# Expose port 80 for the application
EXPOSE 80

# Set the default IIS website as the working directory
WORKDIR C:\\inetpub\\wwwroot
