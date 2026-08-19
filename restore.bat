@echo off
title Windows LAN Sharing Setup - Restore Defaults
color 0C

set "LOGFILE=%~dp0restore.log"

echo.
echo  ====================================================
echo   Windows LAN Sharing Setup - Restore Defaults
echo  ====================================================
echo.

REM ==========================================
REM  ADMIN CHECK
REM ==========================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  [ERROR] This script requires Administrator privileges.
    echo  Right-click the file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM ==========================================
REM  CHECK BACKUP
REM ==========================================
set "BACKUPDIR=%~dp0registry-backup"

if not exist "%BACKUPDIR%" (
    echo  [ERROR] Backup directory not found.
    echo  Make sure you run install.bat first to create backups.
    echo.
    pause
    exit /b 1
)

REM ==========================================
REM  CONFIRMATION
REM ==========================================
echo  This will restore all Windows sharing settings
echo  to their original defaults using the registry backups.
echo.
echo  Backup location: %BACKUPDIR%
echo.
set /p confirm="  Are you sure you want to continue? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo.
    echo  Operation cancelled.
    echo.
    pause
    exit /b 0
)

REM ==========================================
REM  RESTORE REGISTRY
REM ==========================================
echo.
echo  [*] Restoring registry settings...

if exist "%BACKUPDIR%\LanmanWorkstation_Parameters.reg" (
    reg import "%BACKUPDIR%\LanmanWorkstation_Parameters.reg" >nul 2>&1
    if %errorLevel% equ 0 (
        echo   [OK] LanmanWorkstation Parameters restored
        echo  [%date% %time%] LanmanWorkstation restored >> "%LOGFILE%"
    ) else (
        echo   [WARN] LanmanWorkstation restore failed
        echo  [%date% %time%] LanmanWorkstation restore FAILED >> "%LOGFILE%"
    )
) else (
    echo   [SKIP] LanmanWorkstation backup not found
)

if exist "%BACKUPDIR%\Lsa.reg" (
    reg import "%BACKUPDIR%\Lsa.reg" >nul 2>&1
    if %errorLevel% equ 0 (
        echo   [OK] LSA settings restored
        echo  [%date% %time%] LSA restored >> "%LOGFILE%"
    ) else (
        echo   [WARN] LSA restore failed
        echo  [%date% %time%] LSA restore FAILED >> "%LOGFILE%"
    )
) else (
    echo   [SKIP] LSA backup not found
)

if exist "%BACKUPDIR%\LanmanServer_Parameters.reg" (
    reg import "%BACKUPDIR%\LanmanServer_Parameters.reg" >nul 2>&1
    if %errorLevel% equ 0 (
        echo   [OK] LanmanServer Parameters restored
        echo  [%date% %time%] LanmanServer restored >> "%LOGFILE%"
    ) else (
        echo   [WARN] LanmanServer restore failed
        echo  [%date% %time%] LanmanServer restore FAILED >> "%LOGFILE%"
    )
) else (
    echo   [SKIP] LanmanServer backup not found
)

REM ==========================================
REM  RESTORE NETWORK PROFILE
REM ==========================================
echo.
echo  [*] Restoring network profile to Automatic...
powershell -Command "Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Automatic" >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] Network profile set to Automatic
) else (
    echo   [WARN] Failed to restore network profile
)

REM ==========================================
REM  DISABLE FIREWALL RULES
REM ==========================================
echo.
echo  [*] Disabling sharing firewall rules...
netsh advfirewall firewall set rule group="Network Discovery" new enable=No >nul 2>&1
echo   [OK] Network Discovery disabled

netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=No >nul 2>&1
echo   [OK] File and Printer Sharing disabled

REM ==========================================
REM  RESET SERVICES
REM ==========================================
echo.
echo  [*] Resetting services to manual startup...
for %%s in (fdPHost FDResPub SSDPSRV upnphost) do (
    sc config "%%s" start= demand >nul 2>&1
    echo   [OK] %%s set to manual
)

REM ==========================================
REM  SUMMARY
REM ==========================================
echo.
echo  ====================================================
echo   Restore Complete
echo  ====================================================
echo.
echo  A reboot is recommended to apply all changes.
echo  Run verify.bat after reboot to confirm settings.
echo  Log saved to: %LOGFILE%
echo.
echo  ====================================================
echo.
pause
