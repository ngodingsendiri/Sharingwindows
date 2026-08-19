@echo off
title Windows LAN Sharing Setup
color 0A

set "VERSION=1.1.0"
set "LOGFILE=%~dp0sharing-setup.log"
set "BACKUPDIR=%~dp0registry-backup"
set "ERRORCOUNT=0"
set "NOREBOOT=0"
set "QUIET=0"

REM ==========================================
REM  PARSE ARGUMENTS
REM ==========================================
:parse_args
if "%~1"=="" goto :done_args
if /i "%~1"=="--no-reboot" set "NOREBOOT=1"
if /i "%~1"=="--quiet" set "QUIET=1"
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
shift
goto :parse_args

:show_help
echo  Windows LAN Sharing Setup v%VERSION%
echo.
echo  Usage: install.bat [OPTIONS]
echo.
echo  Options:
echo    --no-reboot    Skip automatic reboot
echo    --quiet        Suppress console output (log only)
echo    --help, -h     Show this help message
echo.
echo  Examples:
echo    install.bat                     # Normal install with reboot
echo    install.bat --no-reboot         # Install, reboot manually later
echo    install.bat --quiet             # Silent install
echo    install.bat --quiet --no-reboot # Fully silent, no reboot
echo.
exit /b 0

:done_args

if %QUIET% equ 0 (
    echo.
    echo  ====================================================
    echo   Windows LAN Sharing Setup v%VERSION%
    echo   Enable file/printer sharing across LAN networks
    echo  ====================================================
    echo.
)

REM ==========================================
REM  ADMIN CHECK
REM ==========================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    if %QUIET% equ 0 (
        echo  [ERROR] This script requires Administrator privileges.
        echo  Right-click the file and select "Run as administrator"
        echo.
        pause
    )
    exit /b 1
)

REM ==========================================
REM  BACKUP REGISTRY
REM ==========================================
call :log "  [*] Creating registry backup..."
if not exist "%BACKUPDIR%" mkdir "%BACKUPDIR%"

reg export "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "%BACKUPDIR%\LanmanWorkstation_Parameters.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" "%BACKUPDIR%\Lsa.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "%BACKUPDIR%\LanmanServer_Parameters.reg" /y >nul 2>&1

call :log "  [OK] Registry backup saved to: %BACKUPDIR%"

REM ==========================================
REM  NETWORK PROFILE
REM ==========================================
call :log ""
call :log "  [*] Setting network profile to Private..."
powershell -Command "Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private" >nul 2>&1
if %errorLevel% equ 0 (
    call :log "  [OK] Network profile set to Private"
) else (
    call :log "  [WARN] Failed to set network profile - check manually"
    set /a ERRORCOUNT+=1
)

REM ==========================================
REM  FIREWALL RULES
REM ==========================================
call :log ""
call :log "  [*] Enabling firewall rules..."

call :log "  [*] Network Discovery..."
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul 2>&1
if %errorLevel% equ 0 (
    call :log "  [OK] Network Discovery enabled"
) else (
    call :log "  [WARN] Network Discovery failed"
    set /a ERRORCOUNT+=1
)

call :log "  [*] File and Printer Sharing..."
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul 2>&1
if %errorLevel% equ 0 (
    call :log "  [OK] File and Printer Sharing enabled"
) else (
    call :log "  [WARN] File and Printer Sharing failed"
    set /a ERRORCOUNT+=1
)

REM ==========================================
REM  SERVICES
REM ==========================================
call :log ""
call :log "  [*] Configuring required services..."

call :startservice fdPHost "Function Discovery Provider Host"
call :startservice FDResPub "Function Discovery Resource Publication"
call :startservice SSDPSRV "SSDP Discovery"
call :startservice upnphost "UPnP Device Host"
call :startservice LanmanServer "Server (SMB)"
call :startservice LanmanWorkstation "Workstation (SMB Client)"

REM ==========================================
REM  SMBv1
REM ==========================================
call :log ""
call :log "  [*] Checking SMBv1..."
set "SMB1_STATE="
for /f "tokens=3 delims=: " %%a in ('dism /online /get-featureinfo /featurename:SMB1Protocol 2^>nul ^| findstr /i "State"') do set "SMB1_STATE=%%a"

if /i "%SMB1_STATE%"=="Enabled" (
    call :log "  [OK] SMBv1 already enabled"
) else (
    call :log "  [*] Enabling SMBv1..."
    dism /online /enable-feature /featurename:SMB1Protocol /All /NoRestart >nul 2>&1
    if %errorLevel% equ 0 (
        call :log "  [OK] SMBv1 enabled"
    ) else (
        call :log "  [WARN] SMBv1 enable failed"
        set /a ERRORCOUNT+=1
    )
)

REM ==========================================
REM  REGISTRY SETTINGS
REM ==========================================
call :log ""
call :log "  [*] Configuring registry settings..."

call :addreg "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "AllowInsecureGuestAuth" "REG_DWORD" "1"
call :addreg "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" "everyoneincludesanonymous" "REG_DWORD" "1"
call :addreg "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" "restrictanonymous" "REG_DWORD" "0"
call :addreg "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "AutoShareWks" "REG_DWORD" "1"

REM ==========================================
REM  SUMMARY
REM ==========================================
call :log ""
call :log "  ===================================================="

if %ERRORCOUNT% equ 0 (
    call :log "   [SUCCESS] All configurations completed successfully"
) else (
    call :log "   [DONE] Completed with %ERRORCOUNT% warning(s)"
    call :log "   Check the log for details: %LOGFILE%"
)

call :log "  ===================================================="

if %QUIET% equ 0 (
    echo.
    echo  Installation complete.
    echo  Log saved to: %LOGFILE%
    echo.
)

if %NOREBOOT% equ 1 (
    if %QUIET% equ 0 (
        echo  Reboot skipped. Please reboot manually when ready.
        echo.
        pause
    )
) else (
    if %QUIET% equ 0 (
        echo  The system will reboot in 10 seconds.
        echo  Press Ctrl+C to cancel the reboot.
        echo.
    )
    timeout /t 10
    shutdown /r /t 0 /f
)
exit /b

REM ==========================================
REM  HELPER FUNCTIONS
REM ==========================================

:log
if %QUIET% equ 0 echo %~1
echo %~1 >> "%LOGFILE%"
goto :eof

:startservice
set "svcname=%~1"
set "svcdesc=%~2"
sc config "%svcname%" start= auto >nul 2>&1
sc start "%svcname%" >nul 2>&1
if %errorLevel% equ 0 (
    call :log "  [OK] %svcdesc% (%svcname%)"
) else (
    sc query "%svcname%" 2>nul | findstr /i "RUNNING" >nul 2>&1
    if %errorLevel% equ 0 (
        call :log "  [OK] %svcdesc% (%svcname%) - already running"
    ) else (
        call :log "  [WARN] %svcdesc% (%svcname%) - failed to start"
        set /a ERRORCOUNT+=1
    )
)
goto :eof

:addreg
set "regpath=%~1"
set "regval=%~2"
set "regtype=%~3"
set "regdata=%~4"
reg add "%regpath%" /v "%regval%" /t %regtype% /d %regdata% /f >nul 2>&1
if %errorLevel% equ 0 (
    call :log "  [OK] %regpath%\%regval% = %regdata%"
) else (
    call :log "  [WARN] Failed to set %regpath%\%regval%"
    set /a ERRORCOUNT+=1
)
goto :eof
