@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"

:: Tự động cô lập thư mục tạm TEMP/TMP cho JADX (Khắc phục triệt để morluto/rea Issue #5237 trên Windows x64)
:: Lưu ý: -ExecutionPolicy Bypass là cờ chạy script PowerShell trên Windows, không phải sandbox bảo mật.
if not exist "%LOCALAPPDATA%\Temp" mkdir "%LOCALAPPDATA%\Temp" >nul 2>&1
for %%I in ("%LOCALAPPDATA%\Temp") do (
    set "TEMP=%%~fsI"
    set "TMP=%%~fsI"
)

:: Ưu tiên TypeScript / Node CLI (rea-kit verify)
if exist "%~dp0dist\cli.js" (
    where node >nul 2>&1
    if not errorlevel 1 (
        node "%~dp0dist\cli.js" verify %*
        set "EXIT_CODE=%ERRORLEVEL%"
        goto :finish
    )
)

:: Fallback về PowerShell verify_code.ps1 nếu node hoặc dist/cli.js chưa có
if exist "%~dp0.agents\scripts\verify_code.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0.agents\scripts\verify_code.ps1" %*
    set "EXIT_CODE=%ERRORLEVEL%"
    goto :finish
)

echo [ERROR] Không tìm thấy runtime thực thi kiểm tra hợp lệ (node dist/cli.js hoặc .agents/scripts/verify_code.ps1).
set "EXIT_CODE=1"

:finish
echo.
pause
exit /b %EXIT_CODE%
