@echo off
title Windows LAN Sharing Setup - Verification
color 0A

set "PASS=0"
set "FAIL=0"
set "VERSION=1.0.0"

echo.
echo  ====================================================
echo   Windows LAN Sharing Setup v%VERSION% - Verification
echo  ====================================================
echo.

REM ==========================================
REM  [1] NETWORK PROFILE
REM ==========================================
echo  [1/7] Network Profile
echo  ----------------------------------------------------
powershell -Command "Get-NetConnectionProfile | Select-Object Name, NetworkCategory | Format-Table -AutoSize" 2>nul
if %errorLevel% equ 0 (
    set /a PASS+=1
) else (
    echo   [FAIL] Could not retrieve network profile
    set /a FAIL+=1
)
echo.

REM ==========================================
REM  [2] FIREWALL RULES
REM ==========================================
echo  [2/7] Firewall Rules
echo  ----------------------------------------------------

echo   Network Discovery (DNS):
netsh advfirewall firewall show rule name="Network Discovery (DNS)" dir=in >nul 2>&1
if %errorLevel% equ 0 (
    echo     [OK] Rule exists
    set /a PASS+=1
) else (
    echo     [FAIL] Rule not found
    set /a FAIL+=1
)

echo   Network Discovery (UPnP-In):
netsh advfirewall firewall show rule name="Network Discovery (UPnP-In)" dir=in >nul 2>&1
if %errorLevel% equ 0 (
    echo     [OK] Rule exists
    set /a PASS+=1
) else (
    echo     [FAIL] Rule not found
    set /a FAIL+=1
)

echo   File and Printer Sharing (SMB-In):
netsh advfirewall firewall show rule name="File and Printer Sharing (SMB-In)" dir=in >nul 2>&1
if %errorLevel% equ 0 (
    echo     [OK] Rule exists
    set /a PASS+=1
) else (
    echo     [FAIL] Rule not found
    set /a FAIL+=1
)

echo   File and Printer Sharing (RPC-EPMAP):
netsh advfirewall firewall show rule name="File and Printer Sharing (RPC-EPMAP)" dir=in >nul 2>&1
if %errorLevel% equ 0 (
    echo     [OK] Rule exists
    set /a PASS+=1
) else (
    echo     [FAIL] Rule not found
    set /a FAIL+=1
)
echo.

REM ==========================================
REM  [3] SERVICES
REM ==========================================
echo  [3/7] Services Status
echo  ----------------------------------------------------
for %%s in (fdPHost FDResPub SSDPSRV upnphost LanmanServer LanmanWorkstation) do (
    sc query "%%s" 2>nul | findstr /i "RUNNING" >nul 2>&1
    if %errorLevel% equ 0 (
        echo   [OK] %%s - Running
        set /a PASS+=1
    ) else (
        echo   [FAIL] %%s - NOT Running
        set /a FAIL+=1
    )
)
echo.

REM ==========================================
REM  [4] SMBv1 FEATURE
REM ==========================================
echo  [4/7] SMBv1 Feature
echo  ----------------------------------------------------
set "SMB1_STATE="
for /f "tokens=3 delims=: " %%a in ('dism /online /get-featureinfo /featurename:SMB1Protocol 2^>nul ^| findstr /i "State"') do set "SMB1_STATE=%%a"

if /i "%SMB1_STATE%"=="Enabled" (
    echo   [OK] SMBv1 is Enabled
    set /a PASS+=1
) else (
    echo   [INFO] SMBv1 is Disabled
    set /a PASS+=1
)
echo.

REM ==========================================
REM  [5] REGISTRY SETTINGS
REM ==========================================
echo  [5/7] Registry Settings
echo  ----------------------------------------------------

echo   AllowInsecureGuestAuth:
reg query "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v AllowInsecureGuestAuth 2>nul | findstr /i "0x1" >nul 2>&1
if %errorLevel% equ 0 (
    echo     [OK] Enabled
    set /a PASS+=1
) else (
    echo     [FAIL] Not set
    set /a FAIL+=1
)

echo   everyoneincludesanonymous:
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v everyoneincludesanonymous 2>nul | findstr /i "0x1" >nul 2>&1
if %errorLevel% equ 0 (
    echo     [OK] Enabled
    set /a PASS+=1
) else (
    echo     [FAIL] Not set
    set /a FAIL+=1
)

echo   restrictanonymous:
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v restrictanonymous 2>nul | findstr /i "0x0" >nul 2>&1
if %errorLevel% equ 0 (
    echo     [OK] Disabled (value = 0)
    set /a PASS+=1
) else (
    echo     [FAIL] Not set correctly
    set /a FAIL+=1
)

echo   AutoShareWks:
reg query "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks 2>nul | findstr /i "0x1" >nul 2>&1
if %errorLevel% equ 0 (
    echo     [OK] Enabled
    set /a PASS+=1
) else (
    echo     [FAIL] Not set
    set /a FAIL+=1
)
echo.

REM ==========================================
REM  [6] SHARED FOLDERS
REM ==========================================
echo  [6/7] Shared Folders
echo  ----------------------------------------------------
net share 2>nul
echo.

REM ==========================================
REM  [7] ACCESS TEST
REM ==========================================
echo  [7/7] Access Test
echo  ----------------------------------------------------
echo   Try accessing this PC from another device:
echo   \\%COMPUTERNAME%\
echo.
echo   Or test locally:
echo   \\localhost\
echo.

REM ==========================================
REM  SUMMARY
REM ==========================================
echo  ====================================================
echo   Verification Complete
echo  ====================================================
echo.
echo   Passed: %PASS%
echo   Failed: %FAIL%
echo.

if %FAIL% gtr 0 (
    echo   [!] Some checks failed. Re-run install.bat or
    echo       check the services/registry manually.
) else (
    echo   [OK] All checks passed. Sharing should be working.
)

echo.
echo  ====================================================
echo.
pause
