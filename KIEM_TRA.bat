@echo off
chcp 65001 >nul
cd /d "%~dp0"

:: Tự động cô lập thư mục tạm TEMP/TMP cho JADX (Khắc phục triệt để morluto/rea Issue #5237 trên Windows x64)
if not exist "%LOCALAPPDATA%\Temp" mkdir "%LOCALAPPDATA%\Temp" >nul 2>&1
set "TEMP=%LOCALAPPDATA%\Temp"
set "TMP=%LOCALAPPDATA%\Temp"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0.agents\scripts\health_check.ps1"
set "EXIT_CODE=%ERRORLEVEL%"
echo.
pause
exit /b %EXIT_CODE%
